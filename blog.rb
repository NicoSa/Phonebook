require 'rubygems'
require 'sinatra'
require 'mongo'
require 'bson'


#is for output in the console using foreman start
$stdout.sync = true 

#Connects us to Database hosted on mongohq
connection = Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
#setting variable db equal to database
db = connection['app21586193']

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

#Opens form to fill in names 
get '/new' do
	#renders our form in html and sends it to post '/new'
	'<form method="post" action="new">
		<input name="vorname" type="text" placeholder="First name"></input><br>
		<input name="nachname" type="text" placeholder="Last name"></input>
		<button>Save</button>
	</form>'
end

#Adds new user to database and confirms it
post '/new' do
#set variables for data from form
     vorname = params[:vorname]
     nachname = params[:nachname]
     #for debugging in console
     puts "#{params}"
     #feed collection namen inside database with the values passed from get '/new' via params
     db['namen'].insert({:vorname=> vorname, :nachname=> nachname})
     #confirm adding and provide links to get '/' and get '/new'
     "#{nachname}, #{vorname} have been added! <a href='new'>New</a> <a href='/'>All</a> "
end

#Delete a user from database
get '/delete' do
    #gets id to delete from get '/delete?id=#{document['_id']}'
    id = params[:id]
    #removes entry with that id from database
	db['namen'].remove({:_id=> BSON::ObjectId.from_string(id)})
	#confirms removal and provides links to get '/new' and get '/'
     "Entry with the ID:#{id} was removed! <a href='new'>New</a> <a href='/'>All</a> "
end

#Give 'new' form with current user
get '/update' do
	#gets ID to update from get 'update?id=#{document['_id']}''
	id = params[:id]
	#find ID in database and convert to array
	persons = db['namen'].find({:_id=> BSON::ObjectId.from_string(id)}).to_a
	#convert array database object to hash entry
	person = persons[0]
	#debugging on console
	puts "#{persons}"
	puts "#{person}"
	#set vorname, nachname equal to person hash entries
	vorname = person["vorname"]
	nachname = person["nachname"]
	#debugging
	puts "#{vorname}"
	puts "#{nachname}"
	#form that contains current names and sends ID to post '/update'
	 %{<form method="post" action="update?id=#{id}">
		<input name="vorname" type="text" placeholder="First name" value="#{vorname}"></input><br>
		<input name="nachname" type="text" placeholder="Last name" value="#{nachname}"></input><br>
		<button>Save</button>
	</form>}

end

#updates database with new entry
post '/update' do
	#debugging
	print params
	#gets ID to update from get 'update?id=#{id}'
	id = params[:id]
	#gets new names from form
	vorname = params[:vorname]
	nachname = params[:nachname]
	#find correlating database entry and convert to hash object
	persons = db['namen'].find({:_id=> BSON::ObjectId.from_string(id)}).to_a
	person = persons[0]
	#fill hash with new names from form
	person["vorname"] = vorname
	person["nachname"] = nachname
	#save new entries from person hash to database
	db['namen'].save(person)
	#updated message
     "#{nachname}, #{vorname} has been updated! <a href='new'>New</a> <a href='/'>All</a> "

end




