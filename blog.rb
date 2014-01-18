require 'rubygems'
require 'sinatra'
require 'mongo'
require 'bson'

db = Mongo::Connection.from_uri("mongodb://dev:penis@dharma.mongohq.com:10099/test1")['test1']

#.new['test']


get '/' do
	telefonbuch = db['namen'].find()
	result = telefonbuch.map{|document| "#{document['nachname']}, #{document['vorname']} <a href='delete?id=#{document['_id']}'>Löschen</a>"}.join("<br>")
	result += '<br><a href="new">Neu</a>'
	result
end

get '/new' do
	'<form method="post" action="new">
		<input name="vorname" type="text" placeholder="Vorname"></input><br>
		<input name="nachname" type="text" placeholder="Nachname"></input>
		<button>Speichern</button>
	</form>'
end

post '/new' do
     vorname = params[:vorname]
     nachname = params[:nachname]
     db['namen'].insert({:vorname=> vorname, :nachname=> nachname})
     "#{nachname}, #{vorname} wurde eingetragen! <a href='new'>Neu</a> <a href='/'>Alle</a> "
end

get '/delete' do
    
     id = params[:id]
	db['namen'].remove({:_id=> BSON::ObjectId.from_string(id)})
     "#{id} wurde gelöscht! <a href='new'>Neu</a> <a href='/'>Alle</a> "

end

get '/update' do



end





