require 'json'
require 'date'
require 'net/http'

FUNDS_IDS = {
  "risky_norris" => 186,
  "moderate_pitt" => 187,
  "conservative_clooney" => 188,
  "very_conservative_streep" => 15077
}

def get_price(fund_id, date)
  url = "https://fintual.cl/api/real_assets/#{fund_id}/days?date=#{date}"
  uri = URI(url)
  response = Net::HTTP.get(uri)
  data = JSON.parse(response)
  
  if data["data"].empty?
    puts "No hay datos para la fecha ingresada #{date}. ¿Podrías probar con fechas más recientes?"
    exit
  end
  
  data["data"][0]["attributes"]["price"]
end

def get_performance(investment_date, withdrawal_date)
  performances = {}
  
  FUNDS_IDS.each do |fund, fund_id|
    price_investment = get_price(fund_id, investment_date)
    price_withdrawal = get_price(fund_id, withdrawal_date)
    performances[fund] = (price_withdrawal - price_investment) / price_investment
  end
  
  performances
end

def get_user_input
  valid = false
  until valid
    puts "Ingrese la fecha de creación de la inversión en formato DD/MM/AAAA: "
    investment_date = gets.chomp
    unless validate_date(investment_date)
      puts "Fecha inválida, intente de nuevo."
      next
    end
    puts "Ingrese la fecha de retiro de la inversión en formato DD/MM/AAAA: "
    withdrawal_date = gets.chomp
    unless validate_date(withdrawal_date)
      puts "Fecha inválida, intente de nuevo."
      next
    end
    puts "Ingrese el monto de la inversión: "
    mount = gets.chomp
    begin
      mount = Integer(mount)
      valid = true
    rescue
      puts "Monto inválido, intente de nuevo."
      next
    end
  end
  investment_date = investment_date.tr("/", "-")
  withdrawal_date = withdrawal_date.tr("/", "-")
  [investment_date, withdrawal_date, mount]
end

def validate_date(date)
  begin
    day, month, year = date.split("/").map(&:to_i)
    return false if day < 1 || day > 31
    return false if month < 1 || month > 12
    return false if year > 2024
    true
  rescue
    false
  end
end

def main
  investment_date, withdrawal_date, mount = get_user_input
  performances = get_performance(investment_date, withdrawal_date)
  
  portfolios = JSON.parse(File.read("portfolios.json"))
  
  best_portfolio = nil
  best_portfolio_value = nil
  
  portfolios.each do |portfolio|
    value = 0
    portfolio.each do |fund, quota|
      value += (quota * mount) + (quota * mount * performances[fund])
    end
    if best_portfolio_value.nil? || value > best_portfolio_value
      best_portfolio_value = value
      best_portfolio = portfolio
    end
  end
  
  puts "El mejor portafolio es: #{best_portfolio}"
  puts "Con un valor de: #{best_portfolio_value}"
end

main
