# frozen_string_literal: true

require "json"
require "time"

module Unshell
  class Hook
    attr_reader :name, :events

    def initialize(name, events: [], &block)
      @name = name
      @events = events.map(&:to_sym)
      @handler = block
    end

    def call(event, payload = {})
      return unless events.include?(event)

      @handler&.call(payload.merge(at: Time.now.utc.iso8601))
    rescue StandardError => e
      warn "hook #{name} failed: #{e.message}"
    end
  end
end

on_push = Unshell::Hook.new("notify", events: %w[push tag]) do |payload|
  puts JSON.pretty_generate(payload)
end

on_push.call(:push, { branch: "main", commits: 3 })
