require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

# Show list of lists
get "/lists" do
  @lists = session[:lists]

  erb :lists
end

# Create a new list
get "/lists/new" do
  erb :new_list
end

# Return an error message if the list name is invalid
def error_for_list_name(name)
  if !(1..100).cover?(name.size)
    "List name must be between 1 and 100 characters."
  elsif session[:lists].any? do |list|
    list[:name] == name && name != params[:list_name]
  end
    "The name for the list is already taken."
  end
end

# Add list to session
post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list
  else
    session[:lists] << {name: list_name, todos: []}
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

# Show a single to list
get "/lists/:id" do
  @list = session[:lists][params[:id].to_i]

  erb :list
end

# Edit a list
get "/lists/:id/edit" do
  @list = session[:lists][params[:id].to_i]
  erb :edit_list
end

# Update an existing todolist
post "/lists/:id" do
  list_name = params[:list_name].strip
  @list = session[:lists][params[:id].to_i]

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list
  else
    @list[:name] = list_name
    session[:success] = "The list has been updated."
    redirect "/lists/#{params[:id]}"
  end
end

# Delete a list
post "/lists/:id/delete" do
  list = session[:lists].delete_at(params[:id].to_i)
  session[:success] = "The list \"#{list[:name]}\" has been deleted"
  redirect "/lists"
end
