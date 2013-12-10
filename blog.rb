require 'sinatra'
get '/hi' do
	"Hello World!\n"
end

telefonbuch = {"Nico" => "Saueressig", "Johannes" => "Hofmeister"}
telefonbuch.default = "Unbekannt"

get '/kunde/' do
	vorname = params[:name]
	"Hallo, Herr #{telefonbuch[vorname]} \n"
end

post '/kunde/' do
     vorname = params[:vorname]
     nachname = params[:nachname]
     telefonbuch[vorname] = nachname
     "#{nachname}, #{vorname} wurde eingetragen!"
end