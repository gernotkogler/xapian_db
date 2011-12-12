class PeopleController < ApplicationController

  def index
    @page = Person.search params[:search], :per_page => 20, :page => params[:page]
  end

  def edit
    @person = Person.find params[:id]
  end

  def update
    @person = Person.find(params[:id])
    if @person.update_attributes(params[:person])
      redirect_to :action => 'index'
    else
      render :action => 'edit'
    end
  end

end
