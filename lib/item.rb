require_relative './base'
require_relative './price_data'

module PoeWatch
  class Item < PoeWatch::Base 
    def prices
      @prices ||= PoeWatch::Api.request(PoeWatch::Api::ITEM_API, { id: self.id }, true)["leagues"].map { |league_data| PoeWatch::PriceData.new(league_data) }
    end

    def price_for_leagues(name_or_regexp)
      regexp = name_or_regexp.is_a?(String) ? Regexp.new(name_or_regexp, 'i') : name_or_regexp
      prices.select { |data| data.name.match(regexp) }
    end

    def price_for_league(name_or_regexp)
      prices.find { |data| name_or_regexp.is_a?(String) ? data.name.downcase == name_or_regexp.downcase : data.name.match(name_or_regexp) }
    end
  end
end