# frozen_string_literal: true

class StatusesIndex < Chewy::Index
  include FormattingHelper

  settings index: { refresh_interval: '30s' },
           analysis: {
             tokenizer: {
               sudachi_tokenizer: {
                 type: 'sudachi_tokenizer',
                 discard_punctuation: true,
                 resources_path: 'C:/elasticsearch/config/sudachi/',
                 settings_path: 'C:/elasticsearch/config/sudachi/sudachi.json',
               },
             },
             analyzer: {
               content: {
                 filter: %w(
           lowercase
           cjk_width
          sudachi_part_of_speech
          sudachi_ja_stop
          sudachi_baseform
         ),
                 tokenizer: 'sudachi_tokenizer',
                 type: 'custom',
               },
             },
           }
  #        settings_path: 'C:/elasticsearch/config/sudachi/sudachi.json',
  index_scope ::Status.unscoped.kept.without_reblogs.includes(:media_attachments, :preloadable_poll)

  crutch :mentions do |collection|
    data = ::Mention.where(status_id: collection.map(&:id)).pluck(:status_id, :account_id)
    data.each.with_object({}) { |(id, name), result| (result[id] ||= []).push(name) }
  end

  crutch :favourites do |collection|
    data = ::Favourite.where(status_id: collection.map(&:id)).pluck(:status_id, :account_id)
    data.each.with_object({}) { |(id, name), result| (result[id] ||= []).push(name) }
  end

  crutch :reactions do |collection|
    data = ::Reaction.where(status_id: collection.map(&:id)).pluck(:status_id, :account_id)
    data.each.with_object({}) { |(id, name), result| (result[id] ||= []).push(name) }
  end

  crutch :reblogs do |collection|
    data = ::Status.where(reblog_of_id: collection.map(&:id)).pluck(:reblog_of_id, :account_id)
    data.each.with_object({}) { |(id, name), result| (result[id] ||= []).push(name) }
  end

  crutch :bookmarks do |collection|
    data = ::Bookmark.where(status_id: collection.map(&:id)).pluck(:status_id, :account_id)
    data.each.with_object({}) { |(id, name), result| (result[id] ||= []).push(name) }
  end
  crutch :votes do |collection|
    data = ::PollVote.joins(:poll).where(poll: { status_id: collection.map(&:id) }).pluck(:status_id, :account_id)
    data.each.with_object({}) { |(id, name), result| (result[id] ||= []).push(name) }
  end
  root date_detection: false do
    field :id, type: 'long'
    field :account_id, type: 'long'

    field :text, type: 'text', analyzer: 'content', value: ->(status) { [status.spoiler_text, PlainTextFormatter.new(status.text, status.local?).to_s].concat(status.media_attachments.map(&:description)).concat(status.preloadable_poll ? status.preloadable_poll.options : []).join("\n\n") } do
      field :stemmed, type: 'text', analyzer: 'content'
    end

    field :searchable_by, type: 'long', value: ->(status, crutches) { status.searchable_by(crutches) }
    field :created_at, type: 'date'
  end
end
