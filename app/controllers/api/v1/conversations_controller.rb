class Api::V1::ConversationsController < ApplicationController
  before_action :set_conversation, only: %i[show update destroy archive delete_conversation]

  # GET /api/v1/conversations
  def index
    conversations = @current_user.conversations
                                 .active
                                 .recent
                                 .page(params[:page])
                                 .per(params[:per_page] || 20)

    render json: conversations, each_serializer: ConversationSerializer
  end

  # GET /api/v1/conversations/:id
  def show
    render json: @conversation, 
           serializer: ConversationSerializer,
           include_messages: true
  end

  # POST /api/v1/conversations
  def create
    openai_service = OpenaiAssistantService.new
    
    begin
      # Tạo thread trên OpenAI
      thread_id = openai_service.create_thread
      
      # Tạo conversation trong DB
      conversation = @current_user.conversations.create!(
        title: conversation_params[:title] || "New Conversation",
        openai_thread_id: thread_id,
        status: 'active'
      )

      render json: conversation, 
             serializer: ConversationSerializer,
             status: :created
    rescue StandardError => e
      render json: { 
        error: 'Failed to create conversation',
        message: e.message 
      }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/conversations/:id
  def update
    if @conversation.update(conversation_params)
      render json: @conversation, serializer: ConversationSerializer
    else
      render json: { 
        error: 'Failed to update conversation',
        errors: @conversation.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/conversations/:id
  def destroy
    @conversation.destroy
    head :no_content
  end

  # PATCH /api/v1/conversations/:id/archive
  def archive
    @conversation.archived!  # Enum method
    render json: @conversation, serializer: ConversationSerializer
  end

  # DELETE /api/v1/conversations/:id/delete_conversation
  def delete_conversation
    @conversation.deleted!  # Enum method
    render json: @conversation, serializer: ConversationSerializer
  end

  private

  def set_conversation
    @conversation = @current_user.conversations.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Conversation not found' }, status: :not_found
  end

  def conversation_params
    params.require(:conversation).permit(:title)
  end
end
