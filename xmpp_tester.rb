#!/usr/bin/env ruby

# Created by Ryan Jeffrey

require 'blather/client/dsl'

puts "logging in..."

# Test module that implements the DSL.
module XMPPTest
  extend Blather::DSL
  def self.run; client.run; end

  setup 'ryan@ryanmj.xyz', 'IAmErr0r'
  when_ready {
    puts "Connected ! as #{jid.stripped}."
    begin
      puts "Writing..."
      write_to_stream Blather::Stanza::PubSub::Publish.new("ryanmj.xyz", "testNode", :set, '<data>HELLO</data>')
      puts "Done writing..."
    rescue => e
      pp e
    end
  }

  disconnected { puts "Disconnected ! from #{jid.stripped}." }
  subscription :request? do |stanza|
    puts stanza
    write_to_stream stanza.approve!
  end

  pubsub_subscriptions do |stanza|
    puts stanza
  end

  pubsub_subscription do |stanza|
    puts stanza
  end

  pubsub_event do |stanza|
    puts stanza
  end

  message do |stanza|
    puts stanza
  end

  pubsub_items do |stanza|
    puts stanza
  end
end

#helper = pubsub

# Catpture sigint and sigterm
trap(:INT) { EM.stop }
trap(:TERM) { EM.stop }
# Run event machine.

# Run.
EM.run do
  XMPPTest.run
end
