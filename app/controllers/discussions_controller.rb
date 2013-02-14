# encoding: utf-8

class DiscussionsController < ApplicationController

  requires_authentication
  requires_user           :except => [:index, :search, :search_posts, :show]
  protect_from_forgery    :except => :mark_as_read

  before_filter :load_discussion, :only => [:show, :edit, :update, :destroy, :follow, :unfollow, :favorite, :unfavorite, :search_posts, :mark_as_read, :invite_participant, :remove_participant]
  before_filter :verify_editable, :only => [:edit, :update, :destroy]
  before_filter :load_categories, :only => [:new, :create, :edit, :update]
  before_filter :set_exchange_params
  before_filter :require_and_set_search_query, :only => [:search, :search_posts]
  before_filter :require_categories, :only => [:new, :create]

  protected

    # Loads discussion by params[:id] and checks permissions.
    def load_discussion
      begin
        @discussion = Exchange.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_error 404 and return
      end

      unless @discussion.viewable_by?(@current_user)
        render_error 403 and return
      end
    end

    # Deflects the request unless the discussion is editable by the logged in user.
    def verify_editable
      unless @discussion.editable_by?(@current_user)
        render_error 403 and return
      end
    end

    # This is pretty silly and needs rewriting.
    def set_exchange_params
      if params[:conversation]
        params[:exchange] = params[:conversation]
      elsif params[:discussion]
        params[:exchange] = params[:discussion]
      end
    end

    # Loads the categories.
    def load_categories
      @categories = Category.find(:all).reject{|c| c.trusted? unless (@current_user && @current_user.trusted?)}
    end

    def search_query
      params[:query] || params[:q]
    end

    def require_and_set_search_query
      unless @search_query = search_query
        flash[:notice] = "No query specified!"
        redirect_to discussions_path and return
      end
    end

    def exchange_class
      params[:type] == 'conversation' ? Conversation : Discussion
    end

    def require_categories
      unless @categories.length > 0
        flash[:notice] = "Can't create a new discussion, no categories have been made!"
        redirect_to categories_url and return
      end
    end

    def exchange_params(options={})
      (@current_user.moderator? ? params[:exchange] : Discussion.safe_attributes(params[:exchange])).merge(
        :updated_by => @current_user
      ).merge(options)
    end

  public

    # Recent discussions
    def index
      @discussions = Discussion.viewable_by(@current_user).page(params[:page]).for_view
      load_views_for(@discussions)
    end

    # Popular discussions
    def popular
      @days = params[:days].to_i
      unless (1..180).include?(@days)
        redirect_to params.merge({:days => 7}) and return
      end
      @discussions = Discussion.viewable_by(@current_user).popular_in_the_last(@days.days).page(params[:page])
      load_views_for(@discussions)
    end

    # Searches discusion titles
    def search
      @discussions = Discussion.search_results(search_query, user: @current_user, page: params[:page])

      respond_to do |format|
        format.any(:html, :mobile) do
          load_views_for(@discussions)
          @search_path = search_path
        end
        format.json do
          json = {
            :pages         => @discussions.pages,
            :total_entries => @discussions.total,
            # TODO: Fix when Rails bug is fixed
            #:discussions   => @discussions
            :discussions   => @discussions.map{|d| {:discussion => d.attributes}}
          }.to_json(:except => [:delta])
          render :text => json
        end
      end
    end

    # Searches posts within a discussion
    def search_posts
      @search_path = search_posts_discussion_path(@discussion)
      @posts = Post.search_results(search_query, user: @current_user, exchange: @discussion, page: params[:page])
    end

    # Creates a new discussion
    def new
      @discussion = exchange_class.new
      case exchange_class
      when Discussion
        @discussion.category = Category.find(params[:category_id])
      when Conversation
        @recipient = User.find_by_username(params[:username]) if params[:username]
      end
    end

    # Show a discussion
    def show
      context = (request.format == :mobile) ? 0 : 3
      @posts = @discussion.posts.page(params[:page], context: context).for_view

      # Mark discussion as viewed
      if @current_user
        @current_user.mark_discussion_viewed(@discussion, @posts.last, (@posts.offset_value + @posts.count))
      end
      if @discussion.kind_of?(Conversation)
        @section = :conversations
        ConversationRelationship.find(:first, :conditions => {:conversation_id => @discussion, :user_id => @current_user.id}).update_attribute(:new_posts, false)
        render :template => 'discussions/show_conversation'
      end
    end

    # Edit a discussion
    def edit
      @discussion.body = @discussion.posts.first.body
    end

    # Create a new discussion
    def create
      @discussion = exchange_class.create(exchange_params(:poster => @current_user))
      if @discussion.valid?
        if @discussion.kind_of?(Conversation) && params[:recipient_id]
          ConversationRelationship.create(
            :user         => User.find(params[:recipient_id]),
            :conversation => @discussion,
            :new_posts    => true
          )
        end
        redirect_to discussion_path(@discussion) and return
      else
        flash.now[:notice] = "Could not save your discussion! Please make sure all required fields are filled in."
        render :action => :new
      end
    end

    # Update a discussion
    def update
      @discussion.update_attributes(exchange_params)
      if @discussion.valid?
        flash[:notice] = "Your changes were saved."
        redirect_to discussion_path(@discussion) and return
      else
        flash.now[:notice] = "Could not save your discussion! Please make sure all required fields are filled in."
        render :action => :edit
      end
    end

    # List discussions marked as favorite
    def conversations
      @section = :conversations
      @discussions = @current_user.conversations.page(params[:page]).for_view
      load_views_for(@discussions)
    end

    # List discussions marked as favorite
    def favorites
      @section = :favorites
      @discussions = @current_user.favorite_discussions.viewable_by(@current_user).page(params[:page]).for_view
      load_views_for(@discussions)
    end

    # List discussions marked as followed
    def following
      @section = :following
      @discussions = @current_user.followed_discussions.viewable_by(@current_user).page(params[:page]).for_view
      load_views_for(@discussions)
    end

    # Follow a discussion
    def follow
      DiscussionRelationship.define(@current_user, @discussion, :following => true)
      redirect_to discussion_url(@discussion, :page => params[:page])
    end

    # Unfollow a discussion
    def unfollow
      DiscussionRelationship.define(@current_user, @discussion, :following => false)
      redirect_to discussions_url
    end

    # Favorite a discussion
    def favorite
      DiscussionRelationship.define(@current_user, @discussion, :favorite => true)
      redirect_to discussion_url(@discussion, :page => params[:page])
    end

    # Unfavorite a discussion
    def unfavorite
      DiscussionRelationship.define(@current_user, @discussion, :favorite => false)
      redirect_to discussion_url(@discussion, :page => params[:page])
    end

    # Invite a participant
    def invite_participant
      if @discussion.kind_of?(Conversation) && params[:username]
        usernames = params[:username].split(/\s*,\s*/)
        usernames.each do |username|
          if user = User.find_by_username(username)
            ConversationRelationship.create(:conversation => @discussion, :user => user, :new_posts => true)
          end
        end
      end
      if request.xhr?
        render :template => 'discussions/participants', :layout => false
      else
        redirect_to discussion_url(@discussion)
      end
    end

    # Remove participant from discussion
    def remove_participant
      if @discussion.kind_of?(Conversation)
        @discussion.remove_participant(@current_user)
        flash[:notice] = 'You have been removed from the conversation'
        redirect_to conversations_url and return
      end
    end

    # Mark discussion as read
    def mark_as_read
      last_index = @discussion.posts_count
      last_post = Post.find(:first, :conditions => {:discussion_id => @discussion.id}, :order => 'created_at DESC')
      @current_user.mark_discussion_viewed(@discussion, last_post, last_index)
      if request.xhr?
        render :layout => false, :text => 'OK'
      end
    end
end
