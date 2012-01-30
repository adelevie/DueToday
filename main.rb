require 'open-uri'
require 'json'
require 'hashie'

class DueToday < Sinatra::Base

  get "/issues/:user" do
    repos = Repo.all(params[:user]).map {|r| r.name}
    @issues = []
    repos.each do |r| 
      @issues << Issue.all(params[:user]+"/"+r, repo_name=r)
    end
    @issues.flatten!
    @grouped_issues = @issues.group_by {|i| i.milestone}.sort_by {|milestone, issues| milestone.due_on}
    erb :issues
  end
  
  get "/repo/:user/:repo" do
    repo = "#{params[:user]}/#{params[:repo]}"
    @grouped_issues = Issue.all(repo, repo_name=repo.split("/")[1]).group_by {|i| i.milestone}.sort_by {|milestone, issues| milestone.due_on}
    erb :issues
  end
  
end

class Issue < Hashie::Mash
  
  def self.all(repo, repo_name=nil)
    resp = open("https://api.github.com/repos/#{repo}/issues?per_page=100") {|f| f.read}
    issues = JSON.parse resp
    issues.map {|i| i.merge!({:repo => repo_name})} if repo_name
    issues.map {|i| new(i)}.select {|i| i.milestone}
  end
    
end

class Repo < Hashie::Mash
  def self.all(user)
    resp = open("https://api.github.com/users/adelevie/repos") {|f| f.read}
    repos = JSON.parse resp
    repos.map {|r| new(r)}
  end
end

def alert(n)
  due_on = Date.parse(n)
  today = Time.now.to_date
  if due_on == today
    "error"
  else
    "warning"
  end
end