# frozen_string_literal: true

require_relative './app_uploader'
# require 'byebug'

module FIR
  class AliUploader < AppUploader
    def upload_icon
      if skip_update_icon?
        logger.info 'skip update icon...'
        return
      end
      try_to_action('upload icon') do
        # 拿到 icon 的授权
        icon_url = uploading_info[:cert][:icon][:upload_url]
        icon_info = uploading_icon_info

        logger.debug "icon_url = #{icon_url}, icon_info = #{icon_info}"
        put_file(icon_url, uploading_icon_info, uploading_info[:cert][:icon][:custom_headers])
        callback_to_api(callback_url, callback_icon_information)
      end
    rescue StandardError => e
      # ignore icon error
      logger.info "ignore icon upload error #{e.message}"
    end

    def upload_binary
      try_to_action 'upload binary ...' do
        binary_url = uploading_info[:cert][:binary][:upload_url]
        binary_info = uploading_binary_info

        logger.debug "binary_url = #{binary_url}, binary_info = #{binary_info}"
        headers = uploading_info[:cert][:binary][:custom_headers]
        headers_copy = {
          'CONTENT-DISPOSITION' => headers[:"CONTENT-DISPOSITION"],
          'Content-Type' => headers[:"content-type"],
          'date' => headers[:date],
          'x-oss-date' => headers[:"x-oss-date"],
          'authorization' => headers[:authorization]
        }

        logger.debug headers_copy
        put_file(binary_url, binary_info, headers_copy)
        callback_to_api(callback_url, callback_binary_information)
      end
    rescue StandardError => e
      logger.error "binary upload to ali fail, #{e.message}"
      exit 1
    end

    protected

    def put_file(url, file, headers)
      RestClient::Request.execute(
        method: 'PUT',
        url: url,
        payload: file,
        headers: headers,
        timeout: 300
      )
    end

    def callback_url
      "#{fir_api[:base_url]}/auth/ali/callback"
    end

    def uploading_icon_info
      File.new(icon_file_path, 'rb')
    end

    def uploading_binary_info
      File.new(file_path, 'rb')
    end
  end
end
