include IndexLocation
module Api
  module V2
    class InstagramArtsController < ApplicationController

      def geojson_single
        instagram_art = InstagramArt.find(params[:id])
        respond_to do |format|
          format.json {
            data = IndexLocation.get_response_geojson(instagram_art)
            render json: data,
                   :content_type => 'application/json'
          }
        end
      end

      # GET /find
      def indexlocation
        base_url = ENV['PUBLICART_BASE_URL']
        if params[:search].present?
          next_page = 2
          if params[:distance].present?
            distance_from = params[:distance]
          else
            distance_from = 5
          end
          if params[:page].present?
            next_page = params[:page].to_i + 1
          end
          search_url = base_url.to_s + '/api/find.json/?search=' + URI.encode(params[:search]) + "&page=" + next_page.to_s

          if params[:orderby].present? && params[:orderby] == 'created_at'
            instagram_arts = InstagramArt.order('created_at DESC').near(params[:search], distance_from).where(flagged: nil).page params[:page]
            result_count = InstagramArt.order('created_at DESC').near(params[:search], distance_from).where(flagged: nil).count(:all)
          else
            instagram_arts = InstagramArt.near(params[:search], distance_from).where(flagged: nil).page params[:page]
            result_count = InstagramArt.near(params[:search], distance_from).where(flagged: nil).count(:all)
          end
          result_coordinates = Geocoder.coordinates(params[:search])

          if(params.has_key?(:page))
            page_count = params[:page].to_i
            page_range_low = 1 + (10 * page_count)
          else
            page_count = 1
            page_range_low = 1
          end

          len = instagram_arts.length
          items = IndexLocation.get_response_items instagram_arts, result_coordinates
          @response = {
            location: result_coordinates,
            search_term: params[:search],
            page_number: page_count,
            page_total: instagram_arts.total_pages,
            result: {
              rnext: search_url.html_safe,
              rcount: result_count,
              rlow: page_range_low,
              rhigh: page_range_low + 50
            },
            data: items
          }

          respond_to do |format|
            format.json {
              render :indexlocation
            }
            # format.json {
          end
        end
      end

      # GET /instagram_arts/:id/image
      def image
        instagram_arts = InstagramArt.find(params[:id])
        render json: { id: params[:id], image: instagram_arts.image_url }
      end

    end
  end
end
