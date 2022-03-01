#!/usr/bin/env ruby

# Created by Ryan Jeffrey
# This script is for testing runbuddy's XMPP pubsub system.

require 'blather/client/dsl'
require 'pp'

puts "logging in..."

PUBSUB_HOST = 'chat.ryanmj.xyz'
TEST_NODE = 'testNode'

# For graceful shutdown.
$stop_server = false
# Time since script start (in MS).
$time_spent = 0

def create_test_data
  Nokogiri::XML::DocumentFragment.parse("<data xmlns=\'https://example.org\'>From Ruby: #$time_spent</data>")
end

# Test module that implements the DSL.
module XMPPTest
  extend Blather::DSL
  def self.run; client.run; end

  setup 'ryan@ryanmj.xyz', 'IAmErr0r'
  when_ready {
    puts 'Done logging in.'

    puts "Connected ! as #{jid.stripped}."
    begin
      # TODO patch blather so that it uses a dataform.

      # puts 'Getting subscriptions...'
      # write_to_stream Blather::Stanza::PubSub::Subscriptions.new(:get, PUBSUB_HOST)
      # puts 'Done getting subscriptions.'

      puts 'Setting up a subscription...'
      write_to_stream Blather::Stanza::PubSub::Subscribe.new(:set, PUBSUB_HOST, TEST_NODE, Blather::JID.new('ryan@ryanmj.xyz'))
      puts 'Done setting up a subscription.'

      puts 'Writing a test publish...'
      write_to_stream Blather::Stanza::PubSub::Publish.new(PUBSUB_HOST, TEST_NODE, :set, create_test_data)
      puts 'Done writing test publish.'

      # Request items for the pubsub server every five seconds.
      until $stop_server
        sleep 5
        $time_spent += 5
        puts 'Requesting items from the server...'
        write_to_stream Blather::Stanza::PubSub::Items.request(PUBSUB_HOST, TEST_NODE)
        puts 'Done requesting items.'
        if $time_spent % 60 == 0
          puts 'Writing a test publish...'
          write_to_stream Blather::Stanza::PubSub::Publish.new(PUBSUB_HOST, TEST_NODE, :set, create_test_data)
          puts 'Done writing test publish.'
        end
      end
    rescue => e
      STDERR.puts "Error in setting up pubsub for #{jid.stripped}"
      pp e, STDERR
      EM.stop
    end
  }

  disconnected { puts "Disconnected ! from #{jid.stripped}." }
  # Remember to print items like puts "#{item.pretty_inspect}" or #{item.to_xml}
  # otherwise you get garbled output from multiple threads.

  subscription do |stanza|
    puts "Got a pubsub subscription: #{stanza.to_xml}"
    true
  end

  pubsub_subscriptions do |stanza|
    puts "Got pubsub subscriptions object:\n#{stanza.to_xml}"
    true
  end

  pubsub_publish do |stanza|
    puts "Got a pubsub publish event:\n#{stanza.to_xml}"
    true
  end

  pubsub_subscription do |sub|
    puts "Got a pubsub subscription:\n#{sub.to_xml}"
    true
  end

  pubsub_items do |stanza|
    puts "Got a pubsub item:\n#{stanza.to_xml}"
    true
  end

  pubsub_create do |stanza|
    puts "Got a pubsub create event:\n#{stanza.to_xml}"
    write_to_stream stanza.approve!
    true
  end

  pubsub_event do |stanza|
    puts "Got a general pubsub event:\n#{stanza.to_xml}"
    true
  end

  message do |m|
    puts "Got a message of some sort:\n#{m.to_xml}:"
    true
  end

  status do |status|
    puts "Got a status:\n#{status.to_xml}"
    true
  end

  # Supposed to handle errors but does nothing for pubsub errors :/.
  handle :error do |err|
    puts "Got an error from the server\n#{err.pretty_inspect}"
    true
  end

  # Uncomment this for errors.
  # iq do |stanza, xpath_result|
  #   puts "Got an IQ: #{stanza.pretty_inspect}"
  # end
end

#helper = pubsub

# Catpture sigint and sigterm
trap(:INT) { EM.stop; $stop_server = true }
trap(:TERM) { EM.stop; $stop_server = true }
# Run event machine.

# Run.
EM.run do
  XMPPTest.run
end
