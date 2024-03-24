class WhatsappMethods
  def initialize(wa_id, phone)
    @wa_id = wa_id
    @phone = phone
  end

  def text(message)
    execute_whatsapp({ text: { preview_url: true, body: message } })
  end

  def image(image_url)
    execute_whatsapp({ type: 'image', image: { link: image_url } })
  end

  def reply_buttons(body_text, options = [])
    execute_whatsapp({
                       type: 'interactive',
                       interactive: {
                         type: 'button',
                         body: {
                           text: body_text
                         },
                         action: {
                           buttons: options.map do |option|
                             { type: 'reply', reply: { id: option, title: option } }
                           end
                         }
                       }
                     })
  end

  def list_options(body_text, btn_text, options = [])
    execute_whatsapp({
                       type: 'interactive',
                       interactive: {
                         type: 'list',
                         body: {
                           text: body_text
                         },
                         action: {
                           button: btn_text,
                           sections: [{
                             rows: options.map do |option|
                               { id: option, title: option }
                             end
                           }]
                         }
                       }
                     })
  end

  private

  def execute_whatsapp(message_content)
    api_token = ENV.fetch('META_API_TOKEN') { Rails.application.credentials.dig(:facebook, :access_token) }

    response = HTTParty.post(
      "https://graph.facebook.com/v19.0/#{@wa_id}/messages",
      body: {
        messaging_product: 'whatsapp',
        to: @phone
      }.merge(message_content).to_json,
      headers: {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{api_token}"
      }
    )

    if response.code == 200
      puts '--------- RESPONSE SUCCESS ----------'
      puts response.body
      puts '-------------------------------------'
    else
      puts '--------- RESPONSE ERROR ------------'
      puts "Error: #{response.body}"
      puts '-------------------------------------'
    end
  end
end
