class PeopleController < ApplicationController

  def index
    @page = Person.search params[:search], :per_page => 20, :page => params[:page]
  end

  def edit
    @person = Person.get params[:id]
  end

  def update
    @person = Person.get params[:id]
    if @person.update params[:person]
      redirect_to :action => 'index'
    else
      render :action => 'edit'
    end
  end

end
