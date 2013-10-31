require 'simplecov'
SimpleCov.start

require "minitest/autorun"
require "mocha/setup"
require "fakefs"
require "fileutils"
require_relative "../lib/greybox"
