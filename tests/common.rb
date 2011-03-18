require 'rubygems'
require 'test/unit'

$:.unshift File.join(File.dirname(__FILE__), '..')

ENV['CONDOR_Q_CMD'] = "tests/bin/condor_q"
ENV['CONDOR_SUBMIT_CMD'] = "tests/bin/condor_submit"
ENV['IMAGE_STORAGE'] = "tests/images"
