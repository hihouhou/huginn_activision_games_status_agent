require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::ActivisionGamesStatusAgent do
  before(:each) do
    @valid_options = Agents::ActivisionGamesStatusAgent.new.default_options
    @checker = Agents::ActivisionGamesStatusAgent.new(:name => "ActivisionGamesStatusAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
