class GenericConfirmController < ApplicationController
	def confirm_back
		#raise params[:encounter][:patient_id].to_yaml
		@patient = Patient.find(params[:encounter][:patient_id])
		encounter = Encounter.find(params[:encounter][:encounter_id])
		observations = mirror_observations(encounter, params)
		
		error_message = ''
		confirmed = true
		encounter.observations.each do | observation |
			next if !confirmed
			next if observation.concept_id == ConceptName.find_by_name('WORKSTATION LOCATION').concept_id
			matched = false
			observations.each do | rekeyed_observation |
				if observation.concept_id == rekeyed_observation[:concept_id]
					next if matched
					if observation.value_coded == rekeyed_observation[:value_coded]
						matched = true
					end
					if observation.value_text == rekeyed_observation[:value_text]
						matched = true
					end
					if observation.value_numeric == rekeyed_observation[:value_numeric]
						matched = true
					end
					if observation.value_datetime == rekeyed_observation[:value_datetime]
						matched = true
					end
				end
			end
			if !matched
				confirmed = false
				error_message = 'Could not match ' + observation.to_s
			end  
		end

		if confirmed
			obs = {}
			obs[:concept_name] = 'REKEYED' 
			obs[:value_coded_or_text] = 'YES' 
			obs[:encounter_id] = encounter.id
			obs[:obs_datetime] = Time.now()
			obs[:person_id] ||= encounter.patient_id  
			Observation.create(obs)
			flash[:notice] = "Record rekeyed accurately"
		else
			flash[:error] = error_message
		end

		redirect_to '/patients/confirm/' + @patient.patient_id.to_s
	end

	def confirm
		@patient = Patient.find(params[:encounter][:patient_id])
		encounter = Encounter.find(params[:encounter][:encounter_id])
		@encounter_id = encounter.id
		observations = mirror_observations(encounter, params)
		
		error_message = ''
		confirmed = true
		@unmatched_obs = []

		adc = 0
		nadc = 0
		mine = []
		observations.each do | rekeyed_observation |
			matched = false
			saved_obs = 'NONE'
			encounter.observations.each do | observation |
				if observation.concept_id == rekeyed_observation[:concept_id]
					next if matched
					next if observation.concept_id == ConceptName.find_by_name('WORKSTATION LOCATION').concept_id

					if rekeyed_observation[:value_coded] && observation.value_coded == rekeyed_observation[:value_coded]
						matched = true
					end
					if rekeyed_observation[:value_text] && observation.value_text == rekeyed_observation[:value_text]
						matched = true
					end
					if rekeyed_observation[:value_numeric] && observation.value_numeric == rekeyed_observation[:value_numeric]
						matched = true
					end
					if rekeyed_observation[:value_datetime] && observation.value_datetime == rekeyed_observation[:value_datetime]
						matched = true
					end
					saved_obs = observation.answer_string
				end
			end

			coded_name = Concept.find_by_concept_id(rekeyed_observation[:value_coded]).fullname rescue ''    

			if rekeyed_observation[:value_text] && coded_name.empty?
				coded_name = rekeyed_observation[:value_text]
			end
			if rekeyed_observation[:value_numeric] && coded_name.empty?
				coded_name = rekeyed_observation[:value_numeric]
			end
			if rekeyed_observation[:value_datetime] && coded_name.empty?
				coded_name = rekeyed_observation[:value_datetime]
			end

			if !matched && !coded_name.empty?
				rekeyed_obs = Concept.find(rekeyed_observation[:concept_id]).fullname 
				@unmatched_obs << [rekeyed_obs, coded_name, saved_obs]
				confirmed = false
			end  
		end

		if confirmed
			obs = {}
			obs[:concept_name] = 'REKEYED' 
			obs[:value_coded_or_text] = 'YES' 
			obs[:encounter_id] = encounter.id
			obs[:obs_datetime] = Time.now()
			obs[:person_id] ||= encounter.patient_id  
			Observation.create(obs)
			flash[:notice] = "Record rekeyed accurately"
			redirect_to '/patients/confirm/' + @patient.patient_id.to_s
		else
			session[:saved_params] = params
	        render :action => 'accept'
		end

	end

	def accept
		@patient = Patient.find(params[:encounter][:patient_id])
		encounter = Encounter.find(params[:encounter][:encounter_id])
		@encounter_id = encounter.id
		observations = params[:observations]
		replace = true
		observations.each do | obs |
			next if !replace
			if obs[:value_coded_or_text] == 'NO'
				replace = false
			end
		end
		
		if replace
			encounter.void_obs

			create_obs(encounter , session[:saved_params])

			obs = {}
			obs[:concept_name] = 'REKEYED' 
			obs[:value_coded_or_text] = 'YES' 
			obs[:encounter_id] = encounter.id
			obs[:obs_datetime] = Time.now()
			obs[:person_id] ||= encounter.patient_id  
			Observation.create(obs)

			flash[:notice] = "Record rekeyed and updated!"

			session[:saved_params] = nil
		else
			flash[:notice] = "Record NOT updated!"
		end
		redirect_to '/patients/confirm/' + @patient.patient_id.to_s

	end


	def mirror_observations(encounter, params)
		observations = []
		(params[:observations] || []).each do |observation|
			# Check to see if any values are part of this observation
			# This keeps us from saving empty observations
			values = ['coded_or_text', 'coded_or_text_multiple', 'group_id', 'boolean', 'coded', 'drug', 'datetime', 'numeric', 'modifier', 'text'].map { |value_name|
				observation["value_#{value_name}"] unless observation["value_#{value_name}"].blank? rescue nil
			}.compact
			
			next if values.length == 0

			observation[:value_text] = observation[:value_text].join(", ") if observation[:value_text].present? && observation[:value_text].is_a?(Array)
			observation.delete(:value_text) unless observation[:value_coded_or_text].blank?
			observation[:encounter_id] = encounter.id
			observation[:obs_datetime] = encounter.encounter_datetime || Time.now()
			observation[:person_id] ||= encounter.patient_id
			observation[:concept_name].upcase ||= "DIAGNOSIS" if encounter.type.name.upcase == "OUTPATIENT DIAGNOSIS"
			observation[:concept_id] = ConceptName.find_by_name(observation[:concept_name]).concept_id


			# Handle multiple select

			if observation[:value_coded_or_text_multiple] && observation[:value_coded_or_text_multiple].is_a?(String)
				observation[:value_coded_or_text_multiple] = observation[:value_coded_or_text_multiple].split(';')
			end
      
			if observation[:value_coded_or_text_multiple] && observation[:value_coded_or_text_multiple].is_a?(Array)
				observation[:value_coded_or_text_multiple].compact!
				observation[:value_coded_or_text_multiple].reject!{|value| value.blank?}
			end  
      
			# convert values from 'mmol/litre' to 'mg/declitre'
			if(observation[:measurement_unit])
				observation[:value_numeric] = observation[:value_numeric].to_f * 18 if ( observation[:measurement_unit] == "mmol/l")
				observation.delete(:measurement_unit)
			end

			if(!observation[:parent_concept_name].blank?)
				concept_id = Concept.find_by_name(observation[:parent_concept_name]).id rescue nil
				observation[:obs_group_id] = Observation.find(:last, :conditions=> ['concept_id = ? AND encounter_id = ?', concept_id, encounter.id], :order => "obs_id ASC, date_created ASC").id rescue ""
				observation.delete(:parent_concept_name)
			else
				observation.delete(:parent_concept_name)
				observation.delete(:obs_group_id)
			end

			extracted_value_numerics = observation[:value_numeric]
			extracted_value_coded_or_text = observation[:value_coded_or_text]
      
			#TODO : Added this block with Yam, but it needs some testing.
			if params[:location]
				if encounter.encounter_type == EncounterType.find_by_name("ART ADHERENCE").id
					passed_concept_id = Concept.find_by_name(observation[:concept_name]).concept_id rescue -1
					obs_concept_id = Concept.find_by_name("AMOUNT OF DRUG BROUGHT TO CLINIC").concept_id rescue -1
					if observation[:order_id].blank? && passed_concept_id == obs_concept_id
						order_id = Order.find(:first,
							:select => "orders.order_id",
							:joins => "INNER JOIN drug_order USING (order_id)",
							:conditions => ["orders.patient_id = ? AND drug_order.drug_inventory_id = ? 
										  AND orders.start_date < ?", encounter.patient_id, 
										  observation[:value_drug], encounter.encounter_datetime.to_date],
							:order => "orders.start_date DESC").order_id rescue nil
						if !order_id.blank?
							observation[:order_id] = order_id
						end
					end
				end
			end
      
			if observation[:value_coded_or_text_multiple] && observation[:value_coded_or_text_multiple].is_a?(Array) && !observation[:value_coded_or_text_multiple].blank?
				values = observation.delete(:value_coded_or_text_multiple)
				values.each do |value| 
					observation[:value_coded_or_text] = value
					if observation[:concept_name].humanize == "Tests ordered"
						observation[:accession_number] = Observation.new_accession_number 
					end

					observation = update_observation_value(observation)

					#Observation.create(observation) 
					observations << observation
				end
			elsif extracted_value_numerics.class == Array
				extracted_value_numerics.each do |value_numeric|
					observation[:value_numeric] = value_numeric
					
				  if !observation[:value_numeric].blank? && !(Float(observation[:value_numeric]) rescue false)
						observation[:value_text] = observation[:value_numeric]
						observation.delete(:value_numeric)
					end
									
					#Observation.create(observation)
					observations << observation
				end
			else      
				observation.delete(:value_coded_or_text_multiple)
				observation = update_observation_value(observation) if !observation[:value_coded_or_text].blank?
				
				if !observation[:value_numeric].blank? && !(Float(observation[:value_numeric]) rescue false)
					observation[:value_text] = observation[:value_numeric]
					observation.delete(:value_numeric)
				end
				
				#Observation.create(observation)
				observations << observation
			end
		end
		return observations
  	end

	def update_observation_value(observation)
		value = observation[:value_coded_or_text]
		value_coded_name = ConceptName.find_by_name(value)

		if value_coded_name.blank?
			observation[:value_text] = value
		else
			observation[:value_coded_name_id] = value_coded_name.concept_name_id
			observation[:value_coded] = value_coded_name.concept_id
		end
		observation.delete(:value_coded_or_text)
		return observation
	end



	def rekey
		encounter = Encounter.find(params[:id])
		
		view = ''
		encounter_name = EncounterType.find(encounter.encounter_type).name
		view = 'confirm/' + encounter_name.gsub(' ', '_').downcase
		
		@encounter_id = encounter.id
		@patient = Patient.find(encounter.patient_id)
		@patient_bean = PatientService.get_patient(@patient.person)
		session_date = encounter.encounter_datetime
		@session_date = encounter.encounter_datetime.to_date

		@patient_is_child_bearing_female = is_child_bearing_female(@patient)

		if (encounter_name.upcase rescue '') == 'ANC FOLLOWUP' ||
			(encounter_name.upcase rescue '') == 'PNC FOLLOWUP'

			other = [['Other', 'Other']]

			@arv_drugs = temtct_regimen_options
			@arv_drugs = @arv_drugs - other
			@arv_drugs = @arv_drugs.sort {|a,b| a.to_s.downcase <=> b.to_s.downcase}
			@arv_drugs = @arv_drugs + other
		end

		if (encounter_name.upcase rescue '') == 'ANC FOLLOWUP'
			@patient_is_child_bearing_female = is_child_bearing_female(@patient)
		end


		render :template => view
	end

	def temtct_arv(drug)
		temtct_arv_drugs.map(&:concept_id).include?(drug.concept_id)
	end

	def temtct_arv_drugs
		arv_concept       = ConceptName.find_by_name("TeMTCT ARVs").concept_id
		arv_drug_concepts = ConceptSet.all(:conditions => ['concept_set = ?', arv_concept])
		arv_drug_concepts
	end

  # Generate a given list of Regimen+s for the given +Patient+ <tt>weight</tt>
  # into select options. 
	def temtct_regimen_options
		weight = 5

		if @patient_is_child_bearing_female
			weight = 60
		end
		
		my_drugs = temtct_arv_drugs.map { |t| t.concept_id }

		regimens = nil

		if weight == 5
			regimens = Regimen.find(	:all,
										:order => 'regimen_index',
										:conditions => ['((? >= min_weight AND ? < max_weight) OR (15 >= min_weight AND 15 < max_weight)) AND concept_id IN (?)', weight, weight, my_drugs])
		else
			regimens = Regimen.find(	:all,
										:order => 'regimen_index',
										:conditions => ['? >= min_weight AND ? < max_weight AND concept_id IN (?)', weight, weight, my_drugs])
		end
		
		options = regimens.map { |r|
			concept_name = (r.concept.concept_names.typed("SHORT").first ||	r.concept.concept_names.typed("FULLY_SPECIFIED").first).name
			if r.regimen_index.blank?
				["#{concept_name}","#{concept_name}"]
			else
				if @patient_is_child_bearing_female
					["#{r.regimen_index}A - #{concept_name}", "#{r.regimen_index}A - #{concept_name}"]
				else
					["#{r.regimen_index}P - #{concept_name}", "#{r.regimen_index}P - #{concept_name}"]
				end
			end
		}.sort_by{| r | r[0]}.uniq

		return options
	end

	def is_child_bearing_female(patient)
		patient_bean = PatientService.get_patient(patient.person)
		(patient_bean.sex == 'Female' && patient_bean.age >= 9 && patient_bean.age <= 45) ? true : false
	end

	def observations
		# We could eventually include more here, maybe using a scope with includes
		encounter = Encounter.find(params[:id], :include => [:observations])
		@child_obs = {}
		@observations = []
		encounter.observations.map do |obs|
			next if !obs.obs_group_id.blank?
			if ConceptName.find_by_concept_id(obs.concept_id).name.match(/location/)
				obs.value_numeric = ""
				@observations << obs
			else
				@observations << obs
		  	end
			child_obs = Observation.find(:all, :conditions => ["obs_group_id = ?", obs.obs_id])
			if child_obs
				@child_obs[obs.obs_id] = child_obs
			end
    	end

		render :layout => false
	end

	def create_obs(encounter , params)
		# Observation handling
		# raise params.to_yaml
		(params[:observations] || []).each do |observation|
			# Check to see if any values are part of this observation
			# This keeps us from saving empty observations
			values = ['coded_or_text', 'coded_or_text_multiple', 'group_id', 'boolean', 'coded', 'drug', 'datetime', 'numeric', 'modifier', 'text'].map { |value_name|
				observation["value_#{value_name}"] unless observation["value_#{value_name}"].blank? rescue nil
			}.compact
			
			next if values.length == 0

			observation[:value_text] = observation[:value_text].join(", ") if observation[:value_text].present? && observation[:value_text].is_a?(Array)
			observation.delete(:value_text) unless observation[:value_coded_or_text].blank?
			observation[:encounter_id] = encounter.id
			observation[:obs_datetime] = encounter.encounter_datetime || Time.now()
			observation[:person_id] ||= encounter.patient_id
			observation[:concept_name].upcase ||= "DIAGNOSIS" if encounter.type.name.upcase == "OUTPATIENT DIAGNOSIS"

			# Handle multiple select

			if observation[:value_coded_or_text_multiple] && observation[:value_coded_or_text_multiple].is_a?(String)
				observation[:value_coded_or_text_multiple] = observation[:value_coded_or_text_multiple].split(';')
			end
      
			if observation[:value_coded_or_text_multiple] && observation[:value_coded_or_text_multiple].is_a?(Array)
				observation[:value_coded_or_text_multiple].compact!
				observation[:value_coded_or_text_multiple].reject!{|value| value.blank?}
			end  
      
			# convert values from 'mmol/litre' to 'mg/declitre'
			if(observation[:measurement_unit])
				observation[:value_numeric] = observation[:value_numeric].to_f * 18 if ( observation[:measurement_unit] == "mmol/l")
				observation.delete(:measurement_unit)
			end

			if(!observation[:parent_concept_name].blank?)
				concept_id = Concept.find_by_name(observation[:parent_concept_name]).id rescue nil
				observation[:obs_group_id] = Observation.find(:last, :conditions=> ['concept_id = ? AND encounter_id = ?', concept_id, encounter.id], :order => "obs_id ASC, date_created ASC").id rescue ""
				observation.delete(:parent_concept_name)
			else
				observation.delete(:parent_concept_name)
				observation.delete(:obs_group_id)
			end

			extracted_value_numerics = observation[:value_numeric]
			extracted_value_coded_or_text = observation[:value_coded_or_text]
      
			#TODO : Added this block with Yam, but it needs some testing.
			if params[:location]
				if encounter.encounter_type == EncounterType.find_by_name("ART ADHERENCE").id
					passed_concept_id = Concept.find_by_name(observation[:concept_name]).concept_id rescue -1
					obs_concept_id = Concept.find_by_name("AMOUNT OF DRUG BROUGHT TO CLINIC").concept_id rescue -1
					if observation[:order_id].blank? && passed_concept_id == obs_concept_id
						order_id = Order.find(:first,
							:select => "orders.order_id",
							:joins => "INNER JOIN drug_order USING (order_id)",
							:conditions => ["orders.patient_id = ? AND drug_order.drug_inventory_id = ? 
										  AND orders.start_date < ?", encounter.patient_id, 
										  observation[:value_drug], encounter.encounter_datetime.to_date],
							:order => "orders.start_date DESC").order_id rescue nil
						if !order_id.blank?
							observation[:order_id] = order_id
						end
					end
				end
			end
      
			if observation[:value_coded_or_text_multiple] && observation[:value_coded_or_text_multiple].is_a?(Array) && !observation[:value_coded_or_text_multiple].blank?
				values = observation.delete(:value_coded_or_text_multiple)
				values.each do |value| 
					observation[:value_coded_or_text] = value
					if observation[:concept_name].humanize == "Tests ordered"
						observation[:accession_number] = Observation.new_accession_number 
					end

					observation = update_observation_value(observation)

					Observation.create(observation) 
				end
			elsif extracted_value_numerics.class == Array
				extracted_value_numerics.each do |value_numeric|
					observation[:value_numeric] = value_numeric
					
				  if !observation[:value_numeric].blank? && !(Float(observation[:value_numeric]) rescue false)
						observation[:value_text] = observation[:value_numeric]
						observation.delete(:value_numeric)
					end
									
					Observation.create(observation)
				end
			else      
				observation.delete(:value_coded_or_text_multiple)
				observation = update_observation_value(observation) if !observation[:value_coded_or_text].blank?
				
				if !observation[:value_numeric].blank? && !(Float(observation[:value_numeric]) rescue false)
					observation[:value_text] = observation[:value_numeric]
					observation.delete(:value_numeric)
				end
				
				Observation.create(observation)
			end
		end
  	end

	def update_observation_value(observation)
		value = observation[:value_coded_or_text]
		value_coded_name = ConceptName.find_by_name(value)

		if value_coded_name.blank?
			observation[:value_text] = value
		else
			observation[:value_coded_name_id] = value_coded_name.concept_name_id
			observation[:value_coded] = value_coded_name.concept_id
		end
		observation.delete(:value_coded_or_text)
		return observation
	end

end
