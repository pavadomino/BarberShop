require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'pony'
require 'sqlite3'

configure do
  @db = SQLite3::Database.new 'barbershop.db'
  @db.execute 'CREATE TABLE IF NOT EXISTS
    "Users"
    (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "username" VARCHAR,
      "phone" VARCHAR,
      "barber" VARCHAR,
      "datestamp" VARCHAR,
      "color" VARCHAR
    );'
  @db.execute 'CREATE TABLE IF NOT EXISTS
    "Contacts"
    (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "mailbox" VARCHAR,
      "message" TEXT
    );'
  @db.close
end

get '/' do
	erb "Hello! <a href=\"https://github.com/bootstrap-ruby/sinatra-bootstrap\">Original</a> pattern has been modified for <a href=\"http://rubyschool.us/\">Ruby School</a>"
end

get '/about' do
   @error = 'Something wrong!'
	erb :about
end

get '/visit' do
	erb :visit
end

post '/visit' do
  @username = params[:username]
  @phone = params[:phone]
  @datetime = params[:datetime]
  @barber = params[:barber]
  @color = params[:color]

  hh = { :username => 'Введите имя',
         :phone => 'Введите номер телефона',
         :datetime => 'Введтие дату и время'}

  @error = hh.select { |key,_| params[key] == ''}.values.join(", ")

  if @error != ''
    return erb :visit
  end

  @db = SQLite3::Database.new 'barbershop.db'
  @db.execute 'INSERT INTO
    Users
    (
      username,
      phone,
      barber,
      datestamp,
      color
    )
    VALUES
    (
      ?,?,?,?,?
    )', [@username, @phone, @barber, @datetime, @color]
  @db.close

  erb "#{@username} Вы были успешно записаны!"
end

get '/contacts' do
  erb :contacts
end

post '/contacts' do
  @email = params[:email]
  @comments = params[:comments]

  @db = SQLite3::Database.new 'barbershop.db'
  @db.execute 'INSERT INTO
    Contacts
    (
      mailbox,
      message
    )
    VALUES
    (?,?)', [@email, @comments]
  @db.close

  Pony.mail({
    :from => 'pavadomino@gmail.com',
    :to => 'pavadomino@gmail.com',
    :via => :smtp,
    :subject => "Message from #{@email}",
    :body => "Please check comments from the client:\n#{@comments}",
    :attachments => {"contacts.txt" => File.read("./public/contacts.txt")},
    :via_options => {
      :address              => 'smtp.gmail.com',
      :port                 => '587',
      :enable_starttls_auto => true,
      :user_name            => 'pavadomino@gmail.com',
      :password             => '',
      :authentication       => :plain, # :plain, :login, :cram_md5, no auth by default
      :domain               => "gmail.com" # the HELO domain provided by the client to the server
    }
  })

  erb 'Ваш запрос был отправлен!'
end
