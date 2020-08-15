module Agents
  class ActivisionGamesStatusAgent < Agent
    include FormConfigurable

    can_dry_run!
    no_bulk_receive!
    default_schedule "5m"

    description do
      <<-MD
      The Activision games status  agent fetches servers's status about Activision's games.

      `changes_only` is only used to emit event about a game's status change.

      `all` is only used to filtering only event for All platforms.

      `windows` is only used to filtering only event for Windows's platform.

      `switch` is only used to filtering only event for Switch's platform.

      `xbox1` is only used to filtering only event for Xbox one's platform.

      `play4` is only used to filtering only event for Playstation 4's platform.

      `mac` is only used to filtering only event for Mac's platform.

      `xbox360` is only used to filtering only event for Xbox 360's platform.

      `play3` is only used to filtering only event for Playstation 3's platform.

      `wii` is only used to filtering only event for Wii's platform.

      `ios` is only used to filtering only event for IOs's platform.

      `expected_receive_period_in_days` is used to determine if the Agent is working. Set it to the maximum number of days
      that you anticipate passing without this Agent receiving an incoming Event.
      MD
    end

    event_description <<-MD
      Events look like this:
        {
          "status": "ok",
          "platform": "All platforms",
          "gameTitle": "Call of Duty: Modern Warfare",
          "eventId": "9531",
          "alertId": "a0i4P00000TVnMVQA1"
        }
    MD

    def default_options
      {
#        'game_filter' => {},
        'expected_receive_period_in_days' => '2',
        'changes_only' => 'true',
        'all' => 'true',
        'windows' => 'true',
        'switch' => 'false',
        'xbox1' => 'false',
        'play4' => 'false',
        'mac' => 'false',
        'xbox360' => 'false',
        'play3' => 'false',
        'wii' => 'false',
        'ios' => 'false'
      }
    end

    form_configurable :changes_only, type: :boolean
    form_configurable :all, type: :boolean
    form_configurable :switch, type: :boolean
    form_configurable :xbox1, type: :boolean
    form_configurable :play4, type: :boolean
    form_configurable :mac, type: :boolean
    form_configurable :windows, type: :boolean
    form_configurable :xbox360, type: :boolean
    form_configurable :play3, type: :boolean
    form_configurable :wii, type: :boolean
    form_configurable :ios, type: :boolean
    form_configurable :expected_receive_period_in_days, type: :string
    def validate_options

      if options.has_key?('changes_only') && boolify(options['changes_only']).nil?
        errors.add(:base, "if provided, changes_only must be true or false")
      end

      unless options['expected_receive_period_in_days'].present? && options['expected_receive_period_in_days'].to_i > 0
        errors.add(:base, "Please provide 'expected_receive_period_in_days' to indicate how many days can pass before this Agent is considered to be not working")
      end
    end

    def working?
      memory['last_status'].to_i > 0

      return false if recent_error_logs?
      
      if interpolated['expected_receive_period_in_days'].present?
        return false unless last_receive_at && last_receive_at > interpolated['expected_receive_period_in_days'].to_i.days.ago
      end

      true
    end

    def check
      parse
    end

    private

#    def event_per_filter(status)
#      log " game_filter -> #{interpolated['game_filter']}"
##      game_filter = JSON.parse(interpolated['game_filter'])
#      game_filter.each do |game|
#        log game
#      end
#      log "loop finished"
#    end

    def filter(status)
      create_event = false
      case "#{status['platform']}"
      when "All platforms"
        if interpolated['all'] == 'true'
          create_event = true
        end
      when "Nintendo Switch"
        if interpolated['switch'] == 'true'
          create_event = true
        end
      when "Xbox One"
        if interpolated['xbox1'] == 'true'
          create_event = true
        end
      when "PlayStation 4"
        if interpolated['play4'] == 'true'
          create_event = true
        end
      when "Mac"
        if interpolated['mac'] == 'true'
          create_event = true
        end
      when "Windows"
        if interpolated['windows'] == 'true'
          create_event = true
        end
      when "Xbox 360"
        if interpolated['xbox360'] == 'true'
          create_event = true
        end
      when "PlayStation 3"
        if interpolated['play3'] == 'true'
          create_event = true
        end
      when "Wii U"
        if interpolated['wii'] == 'true'
          create_event = true
        end
      when "iOS"
        if interpolated['ios'] == 'true'
          create_event = true
        end
      end
      if "#{create_event}" == 'true'
#      if create_event == 'true' && game_filter.empty?
        create_event payload: status
#      else
#        event_per_filter(status)
      end
    end

    def parse
      uri = URI.parse("https://support.activision.com/data/online-status-feed.js")
      response = Net::HTTP.get_response(uri)
      
      log "request  status : #{response.code}"
      payload = response.body
      payload = payload.gsub(":null", ": \"ok\"")
      payload = JSON.parse(payload)
      
      if interpolated['changes_only'] == 'true'
        if payload['serverStatuses'].to_s != memory['last_status']
          if "#{memory['last_status']}" == ''
            payload['serverStatuses'].each do |status|
              filter(status)
            end
          else
            last_status = memory['last_status'].gsub("=>", ": ").gsub(": nil", ": null")
            last_status = JSON.parse(last_status)
            payload['serverStatuses'].each do |status|
              found = false
              last_status.each do |statusbis|
                if status == statusbis
                    found = true
                end
              end
              if found == false
                  filter(status)
#                  create_event payload: status
              end
            end
          end
          memory['last_status'] = payload['serverStatuses'].to_s
        end
      else
        create_event payload: payload
        if payload['serverStatuses'].to_s != memory['last_status']
          memory['last_status'] = payload['serverStatuses'].to_s
        end
      end
    end
  end
end
