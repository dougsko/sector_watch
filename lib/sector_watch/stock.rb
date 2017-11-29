require 'csv'
require 'rest-client'
require 'json'

module SectorWatch
    class Stock
        def self.quote(symbol, startdate=nil, enddate=nil, format= nil)
            url = "https://finance.google.com/finance#{!!(startdate || enddate) ? '/historical' : ''}"
            params = {}
            results = []
            params.merge!(output:  !!(startdate || enddate) ? 'csv' : 'json')
            params.merge!(startdate: startdate) if !!(startdate)
            params.merge!(enddate: enddate) if !!(enddate)
            symbol.split(/,/).each do |s|
                params.merge!(q: s)
                u = "#{url}?#{URI.encode_www_form(params)}"
                    RestClient::Request.execute(:url => u, :method => :get, :verify_ssl => false) do |response|
                    if !!(startdate || enddate)
                        fail "Invalid Query" if response.body.match(/^<!DOCTYPE html>/)
                        csv = CSV.new(response.body[3..-1], :headers => true, :header_converters => :symbol, :converters => :all)
                        json = {symbol: s, history: csv.to_a.map {|row| row.to_hash }}
                        if format == 'json'
                            results << json
                        else
                            results << Stock.new(json)
                        end
                    else
                        json = response.body.gsub(/\n/, "")
                        json = json.match(/\/\/ \[/) ? JSON.parse(json[3..-1])[0] : JSON.parse(json)["searchresults"]
                        if json.is_a?(Array)
                            json.each do |j|
                                results << (format=='json' ? j : Stock.new(j))
                            end
                        else
                            results << (format=='json' ? json : Stock.new(json))
                        end
                    end
                end
            end
            return results.length > 1 ? results : results.shift
        end

        def self.calc_change(stock)
            increase = stock[:history].first[:close] - stock[:history].last[:close]
            change = increase / stock[:history].last[:close] * 100
            sprintf('%.2f', change)
        end

        def self.sma(symbol, months)
            start_date = Date.today.prev_month(months).strftime("%m-%d-%Y")
            end_date = Date.today.strftime("%m-%d-%Y")

            stock = quote(symbol, start_date, end_date, 'json')
            total = 0
            stock[:history].each do |history|
                total += history[:close].to_f
            end
            sma = sprintf('%.2f', total / stock[:history].size).to_f
            if stock[:history].first[:close].to_f > sma
                puts "10 month moving average".blue
                puts "#{symbol} is trading above SMA! #{stock[:history].first[:close]} > #{sma}".green
            else
                puts "#{symbol} is trading below SMA! #{sma}" > "#{stock[:history].first[:close]}".red
            end
            puts
        end

    end
end
