require 'open-uri'

class WhatsappContext
  attr_accessor :wa_id,
                :phone,
                :msg_type,
                :msg_body,
                :interactive_reply,
                :user,
                :conversation

  def initialize(webhook_data)
    @wa_id = webhook_data[:phone_number_id]
    @phone = webhook_data[:from]
    @msg_type = webhook_data[:msg_type]
    @msg_body = webhook_data[:msg_body]
    @interactive_reply = webhook_data[:interactive_reply]
    @image_id = webhook_data[:image_id]

    @user = User.find_or_initialize_by(phone_number: @phone)
    @conversation = Conversation.find_or_initialize_by(user: @user)

    @whatsapp = WhatsappMethods.new(@wa_id, @phone)
  end

  def reply_type
    if global_keyword
      :global
    elsif @interactive_reply
      :interactive
    elsif @msg_type == 'text'
      :text
    elsif @msg_type == 'image'
      :image
    end
  end

  def try_again_prompt
    failed_attempts = @conversation.data['failed_attempts'] || 0

    if failed_attempts >= 3
      update_data({ failed_attempts: 0 })
      ask_for_category
      return
    end

    rand = rand(1..3)
    case rand
    when 1
      @whatsapp.text('Sorry, I did not understand that. Please try again.')
    when 2
      @whatsapp.text('I did not get that. Please try again.')
    when 3
      @whatsapp.text('Can you please try again?')
    end
    update_data({ failed_attempts: failed_attempts + 1 })
  end

  def update_data(data)
    @conversation.update(data: @conversation.data.merge(data))
  end

  def handle_global_keyword
    case global_keyword
    when :restart
      @whatsapp.text('Restart Triggered')
    when :debug
      @whatsapp.text('Debugging...')
    end
  end

  def handle_interactive_reply
    reply = @interactive_reply[:id]

    if reply == Conversation.lobby_menus[0]
      step_receipt_upload_prompt
    elsif reply == Conversation.lobby_menus[1]
      step_redeem_points_prompt
    elsif Conversation.prize_menus.include?(reply)
      @whatsapp.text("You have successfully redeemed your points for a prize. Here is your reload ID:\n*#{SecureRandom.hex(5).upcase}*\nPlease keep this ID safe and use it to redeem your prize.")
      step_lobby_menu
    else
      try_again_prompt
    end
  end

  def handle_text_reply
    if user.new_record?
      user.save
      step_user_name_prompt
    elsif @conversation.pending_name?
      step_user_name_received(@msg_body)
    elsif @conversation.pending_receipt_upload?
      @whatsapp.text('Please upload an image of your receipt.')
    elsif @conversation.pending_receipt_location?
      step_receipt_location_received(@msg_body)
    else
      step_lobby_menu
    end
  end

  def handle_image_reply
    if @image_id
      fetch_image_from_whatsapp(@image_id, @user)
      step_receipt_upload_received
    else
      @whatsapp.text('Sorry, I did not receive the image. Please try again.')
    end
  end

  private

  def step_lobby_menu
    @whatsapp.reply_buttons(
      "Hello #{user.full_name}! *Your current points balance is #{user.points}*.\nWhat would you like to do today?",
      Conversation.lobby_menus
    )
  end

  def step_user_name_prompt
    @whatsapp.text('Welcome! Before we get started, can I please have your name?')
    @conversation.update(current_step: :pending_name)
  end

  def step_user_name_received(name)
    @user.update(full_name: name)
    @whatsapp.text("Thank you, #{@user&.full_name}.")
    @conversation.update(current_step: :at_lobby)
    step_lobby_menu
  end

  def step_receipt_upload_prompt
    @whatsapp.text("By submitting your receipt, you will earn points for your purchase once it is verified.\n")
    @whatsapp.text('Please upload a photo of your receipt.')
    @conversation.update(current_step: :pending_receipt_upload)
  end

  def step_receipt_upload_received
    @whatsapp.text('Thank you for uploading your receipt. Where did you make your purchase? (e.g. Tesco, 7-Eleven, etc.)')
    @conversation.update(current_step: :pending_receipt_location)
  end

  def step_receipt_location_received(location)
    @whatsapp.text("Thank you, your purchase at _#{location}_ has been submitted. It will be reviewed shortly and you will be notified of your points.")
    @conversation.update(current_step: :at_lobby)
    step_lobby_menu
  end

  def step_redeem_points_prompt
    @whatsapp.list_options(
      "You have #{user.points} points. What would you like to redeem?",
      'Select A Gift',
      Conversation.prize_menus
    )
  end

  def global_keyword
    restart_keywords = [
      'restart',
      'reset',
      'start over',
      'start again',
      'restart conversation',
      'reset conversation',
      'start over conversation',
      'start again conversation',
      'main menu',
      'menu'
    ]

    if @msg_body == 'DEBUG'
      :debug
    elsif restart_keywords.include?(@msg_body&.strip&.downcase)
      :restart
    else
      false
    end
  end

  def fetch_image_from_whatsapp(image_id, user)
    # response = HTTParty.get(
    #   "https://graph.facebook.com/v19.0/#{@image_id}",
    #   headers: {
    #     'Content-Type' => 'application/json',
    #     'Authorization' => "Bearer #{Rails.application.credentials.dig(:facebook, :access_token)}"
    #   }
    # )

    # if response.code == 200
    #   puts '--------- RESPONSE SUCCESS ----------'
    #   image_url = response.parsed_response['url']
    #   puts "Image URL: #{image_url}"
    #   r = Receipt.new(user_id: user.id)
    #   r.image.attach(io: URI.open(image_url), filename: "whatsapp_image_#{image_id}.jpg")
    #   puts '-------------------------------------'
    # else
    #   puts '--------- RESPONSE ERROR ------------'
    #   puts "Error: #{response.body}"
    #   puts '-------------------------------------'
    # end
  end

  def download_whatsapp_media(media_id, access_token)
    media_url = "https://graph.facebook.com/v19.0/#{media_id}"

    response = HTTParty.get(media_url, headers: { 'Authorization' => "Bearer #{access_token}" })

    if response.code == 200
      media_download_url = response.parsed_response['url']
      download_and_save_media(media_download_url)
    else
      puts "Error fetching media: #{response.body}"
      # Handle retry logic or token renewal as needed
    end
  end

  def download_and_save_media(media_download_url)
    media_content = URI.open(media_download_url)
    # Assuming you have a model like Receipt to attach the media
    receipt = Receipt.new
    receipt.media.attach(io: media_content, filename: "whatsapp_media_#{SecureRandom.uuid}")
    receipt.save!
    puts 'Media saved successfully.'
  rescue StandardError => e
    puts "Error downloading media: #{e.message}"
    # Handle errors as needed
  end
end
