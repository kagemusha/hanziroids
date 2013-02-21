#!/usr/bin/env ruby
# encoding: utf-8

require 'rubygems' rescue nil
$LOAD_PATH.unshift File.join(File.expand_path(__FILE__), "..", "..", "lib")
require 'chingu'
include Gosu
include Chingu

#
# Demonstrating Chingu-traits bounding_circle, bounding_box and collision_detection.
#
TARGET_SIZE = 30
INIT_MATCHES = 6
INIT_LIVES = 6
ADD_INTERVAL = 8

class Game < Chingu::Window

  def initialize(matches)
    super(1000,600)
    @matches = matches
    self.input = {:esc => :exit, :a => :decrease_speed, :s => :increase_speed, :r=>:start}
    #@talk_bubble = Image["talk_bubble.png"]
    Sound["laser.wav"]
    Sound["explosion.wav"]
    Sound["bullet_hit.wav"]
    start
  end

  def start
    self.factor = 1
    game_objects.each &:destroy
    @game_over = false
    @matchers = @matches.keys
    @targets = @matches.values.flatten
    @player = Player.create @matchers, INIT_LIVES, :zorder => 2, :x=>width/2-TARGET_SIZE, :y=>height/2-TARGET_SIZE, :text=>@matchers[0], :size=>TARGET_SIZE
    @collisions = Array.new
    @score = 0
    @score_text = Text.create score_text, :x => 10, :y => 10, :zorder => 55, :size=>18 , :color => Color::YELLOW
    @life_text = Text.create life_text, :x => 100, :y => 10, :zorder => 55, :size=>18 , :color => Color::GREEN
    @target_count = @targets.length
    p "tcount: #{@target_count}"
    @last_add_time = @start_time = Time.now
    INIT_MATCHES.times { add_item }
  end

  def score_text
    "Score: #{@score}"
  end
  def life_text
    "Lives: #{"@" * @player.life_pts}"
  end

  def increase_speed
    game_objects.each { |go| go.velocity_x *= 1.2; go.velocity_y *= 1.2; }
  end
  def decrease_speed
    game_objects.each { |go| go.velocity_x *= 0.8; go.velocity_y *= 0.8; }
  end

  def end_game
    p "ending game"
    @game_over = true
    game_objects.each {|o| o.stop if o.respond_to? :stop }
    char_size = 40
    y = height/2 - 2*char_size
    x = width/2 -150
    if @player.dead?
      Text.create "你死了 (ur dead)!",
                  :x => x, :y => y, :size => char_size, :color => Color::RED
    else
      elapsed = (Time.now - @start_time).to_i
      end_msg = "全部成了! Time of #{(elapsed/60)}:#{"%02d" % (elapsed%60)}"
      Text.create end_msg, :x => x, :y => y, :size => char_size, :color => Color::GREEN
    end
    Text.create "Press 'r' to restart", :x=>x+char_size*2, :y=>y+char_size+15, :size=> 20, :color => Color::YELLOW
    @player.destroy
  end

  def match(player, target)
    [*@matches[player.text]].include? target.text
  end

  def add_item
    text = @targets.shift || "X"
    Target.create :text=>text, :size => TARGET_SIZE, :x => rand(width - TARGET_SIZE), :y => rand(height - TARGET_SIZE)
  end

  def add_items
    if Time.now - @last_add_time > ADD_INTERVAL
      add_item
      @last_add_time = Time.now
    end
  end

  def update
    return if @game_over
    super
    add_items
    old_collisions = @collisions.clone
    @collisions = Array.new
    @player.each_collision(Target) do |player, hanzi|
      @collisions << hanzi
      next if old_collisions.include?(hanzi)

      if match player, hanzi
        Sound["explosion.wav"].play(0.5)
        hanzi.destroy
        player.hit true
        @score += 10
        @target_count -= 1
        end_game if @target_count == 0
      else
        Sound["bullet_hit.wav"].play(0.5)
        player.hit
        @score -= 2
        end_game if player.dead?
      end
      @score_text.text = score_text
      @life_text.text = life_text
      p "collision: #{player.text}, #{hanzi.text}, #{player.life_pts}, #{@target_count}"
    end

    self.caption = "traits bounding_box/circle & collision_detection. Q/W: Size. A/S: Speed. FPS: #{fps} Objects: #{game_objects.size}"
  end
end


class Player < Text
  trait :bounding_box #, :debug => true
  traits :collision_detection, :effect, :velocity
  attr_reader :life_pts

  def initialize(matchers, life_pts, options={})
    super(options)
    @matchers = matchers.shuffle
    self.input = {:holding_right=>:turn_right, :holding_left=>:turn_left,
                  :holding_up=>:accelerate, :space=>:cycle_hanzi}
    self.max_velocity = 10
    @life_pts = @max_pts = life_pts
    @color_increment = 255/@life_pts
    @color_limit = @color_increment * @life_pts
    set_color
    @matcher_count = -1
  end


  def set_color
    green = @life_pts * @color_increment
    self.color = Color.new @color_limit - green, green, 0
  end

  def hit(correct=false)
    @life_pts = correct ? [@life_pts+1, @max_pts].min : [@life_pts-1, 0].max
    set_color
  end

  def dead?
    @life_pts == 0
  end

  def stop
    self.velocity_x = self.velocity_y = 0
  end
  def cycle_hanzi
    @matcher_count+=1
    self.text = @matchers[@matcher_count % @matchers.length]
  end

  def accelerate
    self.velocity_x = Gosu::offset_x(self.angle, 0.5)*self.max_velocity_x
    self.velocity_y = Gosu::offset_y(self.angle, 0.5)*self.max_velocity_y
  end

  def turn_right
    # The same can be achieved without trait 'effect' as: self.angle += 4.5
    rotate(4.5)
  end

  def turn_left
    # The same can be achieved without trait 'effect' as: self.angle -= 4.5
    rotate(-4.5)
  end

  def update
    return if dead?
    self.velocity_x *= 0.95 # dampen the movement
    self.velocity_y *= 0.95

    @x %= $window.width # wrap around the screen
    @y %= $window.height
  end
end


class Target < Text
  trait :bounding_box #, :debug => true
  traits :velocity, :collision_detection

  def setup
    #@image = Image["rect.png"]
    self.velocity_x = 3 - rand * 6
    self.velocity_y = 3 - rand * 6

    # Test to make sure the bounding_box works with all bellow combos
    #self.factor = 2
    #self.factor = -2
    self.rotation_center = :left_top
    #self.rotation_center = :center
    #self.rotation_center = :right_bottom

    #cache_bounding_box
  end

  def update
    return if @stopped
    self.velocity_x = -self.velocity_x  if @x < 0 || @x > $window.width-TARGET_SIZE
    self.velocity_y = -self.velocity_y  if @y < 0 || @y > $window.height-TARGET_SIZE
  end

  def stop
    @stopped = true
    self.velocity_x = self.velocity_y = 0
  end
end

HANZI = { "日"=>"本","工"=>"作","事"=>"情","友"=>"朋","股"=>"屁","济"=>"经","叛"=>"徒",
            "给"=>"力","牛"=>"逼","如归"=>"视死","香辣"=>"肉丝","纽"=>"约","编"=>"程",
            "宝"=>"淘","互"=>"联网","诸葛"=>"亮","指鹿"=>"为马","安"=>"卓","平"=>"板"  }

KID_MATH = { "1"=>"3-2", "2"=>"8/4", "3"=>"1+2", "4"=>"2*2", "5"=>"7-2","6"=>"2*3",
             "7"=>"3.5*2", "8"=>"5+3", "9"=>"3^2"}

PROG_LANGS = {"Ruby"=>["[x,y].max","strs.each &:up_case!", "x,y=y,x",'Kernel.const_get("User")'],
           "Java"=>["Math.max(x,y)","i++"],
           "Errors"=>["1..5.loop",],
           "Rails"=>['"User".constantize']
}

Game.new(KID_MATH).show














