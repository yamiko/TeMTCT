class PeopleController < GenericPeopleController

  def demographics
    # Search by the demographics that were passed in and then return demographics
    people = PatientService.find_person_by_demographics(params)
    result = people.empty? ? {} : PatientService.demographics(people.first)
    render :text => result.to_json
  end
  
  def confirm
    session_date = session[:datetime] || Date.today
    if request.post?
      redirect_to search_complete_url(params[:found_person_id], params[:relation]) and return
    end
    @found_person_id = params[:found_person_id] 
    @relation = params[:relation]
    @person = Person.find(@found_person_id) rescue nil
    @task = main_next_task(Location.current_location, @person.patient, session_date.to_date)
    @arv_number = PatientService.get_patient_identifier(@person, 'ARV Number')
	  @patient_bean = PatientService.get_patient(@person)
    render :layout => false
  end

  def create
   
    hiv_session = false
    if current_program_location == "HIV program"
      hiv_session = true
    end
    
    person = PatientService.create_patient_from_dde(params) if create_from_dde_server

    unless person.blank?
      if use_filing_number and hiv_session
        PatientService.set_patient_filing_number(person.patient) 
        archived_patient = PatientService.patient_to_be_archived(person.patient)
        message = PatientService.patient_printing_message(person.patient,archived_patient,creating_new_patient = true)
        unless message.blank?
          print_and_redirect("/patients/filing_number_and_national_id?patient_id=#{person.id}" , next_task(person.patient),message,true,person.id)
        else
          print_and_redirect("/patients/filing_number_and_national_id?patient_id=#{person.id}", next_task(person.patient)) 
        end
      else
        print_and_redirect("/patients/national_id_label?patient_id=#{person.id}", next_task(person.patient))
      end
      return
    end

    success = false
    Person.session_datetime = session[:datetime].to_date rescue Date.today

    #for now BART2 will use BART1 for patient/person creation until we upgrade BART1 to 2
    #if GlobalProperty.find_by_property('create.from.remote') and property_value == 'yes'
    #then we create person from remote machine
    if create_from_remote
      person_from_remote = PatientService.create_remote_person(params)
      person = PatientService.create_from_form(person_from_remote["person"]) unless person_from_remote.blank?

      if !person.blank?
        success = true
        person.patient.remote_national_id
      end
    else
      success = true
      person = PatientService.create_from_form(params[:person])
    end

    if params[:person][:patient] && success
		  	if !params[:identifier].empty?	
					patient_identifier = PatientIdentifier.new
					patient_identifier.type = PatientIdentifierType.find_by_name("National id")
					patient_identifier.identifier = params[:identifier]
					patient_identifier.patient = person.patient
					patient_identifier.save!
				end

      PatientService.patient_national_id_label(person.patient)
      unless (params[:relation].blank?)
        redirect_to search_complete_url(person.id, params[:relation]) and return
      else


      redirect_to next_task(person.patient)
      end
    else
      # Does this ever get hit?
      redirect_to :action => "index"
    end
  end

  def search
		found_person = nil
		if params[:identifier]
			local_results = PatientService.search_by_identifier(params[:identifier])

			if local_results.length > 1
				@people = PatientService.person_search(params)
			elsif local_results.length == 1
				found_person = local_results.first
			else
				# TODO - figure out how to write a test for this
				# This is sloppy - creating something as the result of a GET
				if create_from_remote
					found_person_data = PatientService.find_remote_person_by_identifier(params[:identifier])
					found_person = PatientService.create_from_form(found_person_data['person']) unless found_person_data.blank?
				end
			end
			if found_person

        patient = DDEService::Patient.new(found_person.patient)

        patient.check_old_national_id(params[:identifier])

				if params[:relation]
					redirect_to search_complete_url(found_person.id, params[:relation]) and return
				else
					redirect_to :action => 'confirm', :found_person_id => found_person.id, :relation => params[:relation] and return
				end
			end			
		end

#		records_per_page = CoreService.get_global_property_value('records_per_page') || 5
		@relation = params[:relation]
		@people = PatientService.person_search(params)
		@patients = []
    @people.each do | person |
			patient = PatientService.get_patient(person) rescue nil
			@patients << patient
		end

		# Check for study format	
		if params[:identifier]
			study_id =	params[:identifier]
			valid_id = false

			study_site = study_id[0, 2].to_i rescue 0
			p_id = study_id[2, 3].to_i rescue 0
			p_type = study_id[5, 1] rescue ''

			if study_site >= 10 && study_site <=39 && p_id >= 101 && p_id <= 178 && (p_type == 'M' || p_type == 'C' || p_type == 'T') && study_id.length == 6
				valid_id = true
			end 
		
			if valid_id != true
				flash[:error] = "Invalid participant ID"
				redirect_to '/clinic' and return
			end
		end

	end


end


