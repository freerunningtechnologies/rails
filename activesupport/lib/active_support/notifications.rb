require 'active_support/core_ext/module/delegation'

module ActiveSupport
  # Notifications provides an instrumentation API for Ruby. To instrument an
  # action in Ruby you just need to do:
  #
  #   ActiveSupport::Notifications.instrument(:render, :extra => :information) do
  #     render :text => "Foo"
  #   end
  #
  # You can consume those events and the information they provide by registering
  # a log subscriber. For instance, let's store all instrumented events in an array:
  #
  #   @events = []
  #
  #   ActiveSupport::Notifications.subscribe do |*args|
  #     @events << ActiveSupport::Notifications::Event.new(*args)
  #   end
  #
  #   ActiveSupport::Notifications.instrument(:render, :extra => :information) do
  #     render :text => "Foo"
  #   end
  #
  #   event = @events.first
  #   event.name      #=> :render
  #   event.duration  #=> 10 (in milliseconds)
  #   event.result    #=> "Foo"
  #   event.payload   #=> { :extra => :information }
  #
  # When subscribing to Notifications, you can pass a pattern, to only consume
  # events that match the pattern:
  #
  #   ActiveSupport::Notifications.subscribe(/render/) do |event|
  #     @render_events << event
  #   end
  #
  # Notifications ships with a queue implementation that consumes and publish events
  # to log subscribers in a thread. You can use any queue implementation you want.
  #
  module Notifications
    autoload :Instrumenter, 'active_support/notifications/instrumenter'
    autoload :Event, 'active_support/notifications/instrumenter'
    autoload :Fanout, 'active_support/notifications/fanout'

    class << self
      attr_writer :notifier
      delegate :publish, :subscribe, :unsubscribe, :to => :notifier
      delegate :instrument, :to => :instrumenter

      def notifier
        @notifier ||= Notifier.new
      end

      def instrumenter
        Thread.current[:"instrumentation_#{notifier.object_id}"] ||= Instrumenter.new(notifier)
      end
    end

    class Notifier
      def initialize(queue = Fanout.new)
        @queue = queue
      end

      def publish(*args)
        @queue.publish(*args)
      end

      def subscribe(pattern = nil, &block)
        @queue.bind(pattern).subscribe(&block)
      end

      def unsubscribe(subscriber)
        @queue.unsubscribe(subscriber)
      end

      def wait
        @queue.wait
      end
    end
  end
end
