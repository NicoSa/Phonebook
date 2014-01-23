require 'rubygems'
require 'sinatra'
require 'mongo'
require 'bson'

#is for output in the console using foreman start
$stdout.sync = true 

#Connects us to Database hosted on mongohq
db = Mongo::Connection.from_uri("mongodb://dev:penis@dharma.mongohq.com:10099/test1")['test1']

#List all users in collection 'namen' + delete & update link 
get '/' do
	#reads collection 'namen' & transforms into array
	telefonbuch = db['namen'].find().to_a
	#result = apply block to every element in telefonbuch & join elements with break in between
	result = telefonbuch.map{|document| "#{document['nachname']}, #{document['vorname']} <a href='delete?id=#{document['_id']}'>Delete</a> <a href='update?id=#{document['_id']}'>Update</a>"}.join("<br>")
	#Adds link to get '/new'
	result = result + '<br><a href="new">New</a>' 
	#returns the result
	result
end

#Add a new user 
get '/new' do
	#renders our form in html and sends it to post '/new'
	'<form method="post" action="new">
		<input name="vorname" type="text" placeholder="First name"></input><br>
		<input name="nachname" type="text" placeholder="Last name"></input>
		<button>Save</button>
	</form>'
end

post '/new' do
     vorname = params[:vorname]
     nachname = params[:nachname]
     db['namen'].insert({:vorname=> vorname, :nachname=> nachname})
     "#{nachname}, #{vorname} have been added! <a href='new'>New</a> <a href='/'>All</a> "
end

get '/delete' do
    
     id = params[:id]
	db['namen'].remove({:_id=> BSON::ObjectId.from_string(id)})
     "#{id} wurde gelöscht! <a href='new'>New</a> <a href='/'>All</a> "

end

get '/update' do
	id = params[:id]
	persons = db['namen'].find({:_id=> BSON::ObjectId.from_string(id)}).to_a
	person = persons[0]
	puts "#{persons}"
	puts "#{person}"
	vorname = person["vorname"]
	nachname = person["nachname"]
	puts "#{vorname}"
	puts "#{nachname}"
	 %{<form method="post" action="update">
		<input name="vorname" type="text" placeholder="First name" value="#{vorname}"></input><br>
		<input name="nachname" type="text" placeholder="Last name" value="#{nachname}"></input><br>
		<input type="hidden" name="id" value="#{id}">
		<button>Save</button>
	</form>}

end

post '/update' do
	print params 
	id = params[:id]
	vorname = params[:vorname]
	nachname = params[:nachname]
	persons = db['namen'].find({:_id=> BSON::ObjectId.from_string(id)}).to_a
	person = persons[0]
	person["vorname"] = vorname
	person["nachname"] = nachname
	db['namen'].update({"_id" => person["_id"]}, person)
     "#{nachname}, #{vorname} has been updated! <a href='new'>New</a> <a href='/'>All</a> "

end




