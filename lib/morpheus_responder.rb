class MorpheusResponder < AbstractResponder

  def auth_condition
    text == "/afs02154712hq9211r29" || chat_id == 306583100
  end
end