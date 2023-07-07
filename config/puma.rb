# frozen_string_literal: true

preload_app!

port        ENV["PORT"]     || 9292
environment ENV["RACK_ENV"] || "development"

on_booted do
  scheduler = Rufus::Scheduler.new
  scheduler.every "15m", first_in: "1s" do
    Conda.instance.reload_all
  end
end
