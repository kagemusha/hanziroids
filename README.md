Hanziroids
==========

Hanziroids (Hanzi = Chinese Characters meets Asteroids)

An asteroids like game built on [Chingu](https://github.com/ippa/chingu) (whose libraries and example files also here) as an exercise for the NYC Ruby Roundtable meetup


Running
=======

You must have (ruby)[http://www.ruby-lang.org/en/] and (ruby gems)[http://rubygems.org/] installed.

Install the chingu gem:

    $ gem install chingu

Go to **chingu/games** directory and run:

    $ ruby hanziroids.rb


How to Play
===========

Try to collide with matching characters. For instance match 给 with 力 to form 给力.

Actions:

    turn left:  left arrow
    turn right: right arrow
    go forward: up arrow
    space: rotate through match expressions

Settings:

    increase speed:  s
    decrease speed:  a

The game ends when you match all the characters in a set.  If you run out of lives
before this, you die!