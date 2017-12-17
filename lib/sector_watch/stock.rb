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
                puts "10 Month Moving Average".blue
                puts "#{symbol} is trading above SMA #{stock[:history].first[:close]} > #{sma}".green
            else
                puts "#{symbol} is trading below SMA #{sma}" > "#{stock[:history].first[:close]}".red
            end
            puts
        end

        def self.performance(symbol, months)
            start_date = Date.today.prev_month(months.sort.last).strftime("%m-%d-%Y")
            end_date = Date.today.strftime("%m-%d-%Y")

            stock = quote(symbol, start_date, end_date, 'json')
            stock[:changes] = []
            new_stock = {}
            new_stock[:history] = []

            months.each do |month|
                start_date = Date.today.prev_month(month)#.strftime("%m-%d-%Y")
                end_date = Date.today#.strftime("%m-%d-%Y")

                stock[:history].each do |history|
                    if Date.parse(history[:date]) >= start_date and Date.parse(history[:date]) < end_date
                       new_stock[:history] << history
                    end
                end 
                change = calc_change(new_stock)
                stock[:changes] << change
            end
            stock[:changes].map!{|change| change.to_f}
            stock[:performance] = stock[:changes].reduce(:+).to_f / stock[:changes].size.to_f
            stock
        end

        def self.print_results(stocks, months)
            stocks.sort_by!{ |stock| stock[:performance].to_f}.reverse!

            # find and print S&P 500 10 month simple moving average
            stock = SectorWatch::Stock.sma('SPY', 10)

            # print results
            i = 0
            total_percent = 0
            top_three = stocks.first(3)
            top_three.each do |s|
                total_percent += s[:performance].to_f
            end

            puts "Comparing #{months.join(', ')} Month Performance".yellow
            puts "Symbol | % Change | % of Portfolio".blue
            puts "----------------------------------".blue
            stocks.first(15).each do |s|
                if i < 3
                    puts "#{s[:symbol]}\t#{s[:performance].to_f.round(2)}\t#{(s[:performance].to_f / total_percent * 100).round.to_i}".green
                else
                    puts "#{s[:symbol]}\t#{s[:performance].to_f.round(2)}"
                end
                i += 1
            end
        end




    end
end
