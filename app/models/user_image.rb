# == Schema Information
#
# Table name: user_images
#
#  id                     :integer          not null, primary key
#  user_id                :integer          not null
#  thumbnail_data         :binary(214748364
#  thumbnail_content_type :string(255)
#  data                   :binary(214748364
#  content_type           :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#
# Indexes
#
#  index_user_images_on_user_id  (user_id)
#

class UserImage < ActiveRecord::Base
  belongs_to :user

  attr_reader :uploaded_image
  attr_reader :uploaded_thumbnail

  validate :check_image

  IMAGE_TYPES = { "image/jpeg" => "jpg", "image/gif" => "gif", "image/png" => "png" }
  THUMBNAIL_WIDTH = 150
  THUMBNAIL_HEIGHT = 150

  before_save do
    if data_changed? and !data.nil?
      thumbnail = Magick::Image.from_blob(data).first.resize_to_fill(THUMBNAIL_WIDTH, THUMBNAIL_HEIGHT)
      self.thumbnail_data = thumbnail.to_blob
      self.thumbnail_content_type = content_type
    end
  end

  def thumbnail_extension
    IMAGE_TYPES[thumbnail_content_type]
  end

  def extension
    IMAGE_TYPES[content_type]
  end

  def uploaded_thumbnail=(thumbnail)
    self.thumbnail_content_type = convert_content_type(thumbnail.content_type)
    self.thumbnail_data = thumbnail.read
    @uploaded_thumbnail = thumbnail
  end

  def uploaded_image=(image)
    self.content_type = convert_content_type(image.content_type)
    self.data = image.read
    @uploaded_image = image
  end

  def check_image
    if @uploaded_image
      if data.size > 20.megabytes
        errors.add(:uploaded_image, :too_big_image)
      end
      unless IMAGE_TYPES.has_key?(content_type)
        errors.add(:uploaded_image, :invalid_image)
      end
    end
  end

  private
  def convert_content_type(ctype)
    ctype = ctype.rstrip.downcase
    case ctype
    when "image/pjpeg" then "image/jpeg"
    when "image/jpg" then "image/jpeg"
    when "image/x-png"  then "image/png"
    else ctype
    end
  end
end
