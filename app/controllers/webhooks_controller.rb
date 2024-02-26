class WebhooksController < ActionController::API
  def create # POST /webhook
    body = request.raw_post

    puts JSON.pretty_generate(JSON.parse(body))
    return head :not_found unless params[:object]
    return head :ok unless user_initiated_message?(params)

    webhook_data = extract_webhook_data(params)
    return head :bad_request unless webhook_data

    context = WhatsappContext.new(webhook_data)
    user = context.user
    conversation = context.conversation
    reply_type = context.reply_type

    context.handle_global_keyword if reply_type == :global
    context.handle_interactive_reply if reply_type == :interactive
    context.handle_text_reply if reply_type == :text
    context.handle_image_reply if reply_type == :image

    head :ok
  end

  # GET /webhook
  def show
    mode = params['hub.mode']
    token = params['hub.verify_token']
    challenge = params['hub.challenge']

    return unless mode && token

    if mode == 'subscribe' && token == Rails.application.credentials.dig(:facebook, :verify_token)
      render plain: challenge
    else
      head :forbidden
    end
  end

  private

  def user_initiated_message?(params)
    params.dig(:entry, 0, :changes, 0, :field) == 'messages' &&
      !params.dig(:entry, 0, :changes, 0, :value, :messages).nil?
  end

  def extract_webhook_data(params)
    return nil unless params.dig(:entry, 0, :changes, 0, :value, :messages, 0)

    message = params.dig(:entry, 0, :changes, 0, :value, :messages, 0)
    {
      phone_number_id: params.dig(:entry, 0, :changes, 0, :value, :metadata, :phone_number_id),
      from: message[:from],
      msg_type: message[:type],
      msg_body: message.dig(:text, :body),
      interactive_reply: message.dig(:interactive, :button_reply) || message.dig(:interactive, :list_reply),
      image_id: message.dig(:image, :id)
    }
  end
end
