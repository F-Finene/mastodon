# frozen_string_literal: true

class ActivityPub::EmojiReactSerializer < ActivityPub::Serializer
  attributes :id, :type, :actor, :content
  attribute :virtual_object, key: :object

  has_one :custom_emoji, key: :tag, serializer: ActivityPub::EmojiSerializer, if: -> { object.custom_emoji.present? }

  def id
    [ActivityPub::TagManager.instance.uri_for(object.account), '#emoji_reacts/', object.id].join
    #[ActivityPub::TagManager.instance.uri_for(object.account), '#likes/', object.id].join
  end

  def type
    'Like'
  end

  def actor
    ActivityPub::TagManager.instance.uri_for(object.account)
  end

  def virtual_object
    ActivityPub::TagManager.instance.uri_for(object.status)
  end

  def content
    object.custom_emoji.present? ? ":#{object.name}:" : object.name
  end

  def virtual_tags
    [object.custom_emoji]
  end
end
