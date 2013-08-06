class SessionsController < GenericSessionsController

	def study_locations
		field_name = "name"
		Location.find_by_sql("SELECT *
			FROM location
				WHERE location_id IN (SELECT location_id
					FROM location_tag_map
					WHERE location_tag_id = (SELECT location_tag_id
						FROM location_tag
						WHERE name = 'PRIME Study Facilities'))
				ORDER BY name ASC").collect{|name| name.send("name")} rescue []
	end

	# Form for entering the location information
	def location
		@login_wards = study_locations

		if (CoreService.get_global_property_value('select_login_location').to_s == "true" rescue false)
			render :template => 'sessions/select_location'
		end
	end

	# Update the session with the location information
	def update    
		# First try by id, then by name
		location = Location.find(params[:location]) rescue nil
		location ||= Location.find_by_name(params[:location]) rescue nil

		valid_location = (study_locations.include?(location.name)) rescue false

		unless location and valid_location
			flash[:error] = "Invalid study location"

			@login_wards = study_locations
			if (CoreService.get_global_property_value('select_login_location').to_s == "true" rescue false)
				render :template => 'sessions/select_location'
			else
				render :action => 'location'
			end
			return    
		end
		self.current_location = location
		if use_user_selected_activities and not location.name.match(/Outpatient/i)
			redirect_to "/user/activities/#{current_user.id}"
		else
			redirect_to '/clinic'
		end
	end


end
