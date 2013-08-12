class EncountersController < GenericEncountersController

	def new
		@patient = Patient.find(params[:patient_id] || session[:patient_id])
		@patient_bean = PatientService.get_patient(@patient.person)
		session_date = session[:datetime].to_date rescue Date.today
		@session_date = session[:datetime].to_date rescue Date.today

		if session[:datetime]
			@retrospective = true 
		else
			@retrospective = false
		end
		
		@procedures = []
		@proc =  GlobalProperty.find_by_property("facility.procedures").property_value.split(",") rescue []

		@proc.each{|proc|
		  proc_concept = ConceptName.find_by_name(proc, :conditions => ["voided = 0"]).concept_id rescue nil
		  @procedures << [proc, proc_concept] if !proc_concept.nil?
		}

		@diagnosis_type = params[:diagnosis_type]

		@current_height = PatientService.get_patient_attribute_value(@patient, "current_height")
		@min_weight = PatientService.get_patient_attribute_value(@patient, "min_weight")
		@max_weight = PatientService.get_patient_attribute_value(@patient, "max_weight")
		@min_height = PatientService.get_patient_attribute_value(@patient, "min_height")
		@max_height = PatientService.get_patient_attribute_value(@patient, "max_height")
		@select_options = select_options

		@select_options = select_options
		@patient_is_child_bearing_female = is_child_bearing_female(@patient)


		if (params[:encounter_type].upcase rescue '') == 'TEMTCT_REGISTRATION'
			@require_temtct_registration = require_temtct_registration
		end
		

		if (params[:encounter_type].upcase rescue '') == 'ANC_FOLLOWUP'

			other = ['Other', 'Other']

			@arv_drugs = temtct_regimen_options
			@arv_drugs = @arv_drugs - other
			@arv_drugs = @arv_drugs.sort {|a,b| a.to_s.downcase <=> b.to_s.downcase}
			@arv_drugs = @arv_drugs + other
		end

		if (params[:encounter_type].upcase rescue '') == 'ANC_FOLLOWUP'
			@patient_is_child_bearing_female = is_child_bearing_female(@patient)
		end

		redirect_to "/" and return unless @patient

		redirect_to next_task(@patient) and return unless params[:encounter_type]


		if params[:encounter_type].upcase == 'ADMISSION DIAGNOSIS' || params[:encounter_type].upcase == 'DISCHARGE DIAGNOSIS' || params[:encounter_type].upcase == 'OUTPATIENT_DIAGNOSIS'
			if !is_encounter_available(@patient, 'VITALS', session_date) && @patient_bean.age <= 14
				session[:original_encounter] = params[:encounter_type]
				params[:encounter_type] = 'vitals'					
			else
				#if !is_encounter_available(@patient, 'PRESENTING COMPLAINTS', session_date)
				#	session[:original_encounter] = params[:encounter_type]
				#	params[:encounter_type] = 'presenting_complaints'					
				#end
			end
		end
		
		if (params[:encounter_type].upcase rescue '') == 'HIV_STAGING' and  (CoreService.get_global_property_value('use.extended.staging.questions').to_s == "true" rescue false)
			render :template => 'encounters/extended_hiv_staging'
		else
      if params[:encounter_type].upcase == "INFLUENZA"
        render :layout => "multi_touch", :action => params[:encounter_type]
      else
        render :action => params[:encounter_type] if params[:encounter_type]
      end
			 	
		end

	end

	def select_options
		select_options = {
      'reason_for_tb_clinic_visit' => [
        ['',''],
        ['Clinical review (Children, Smear-, HIV+)','CLINICAL REVIEW'],
        ['Smear Positive (HIV-)','SMEAR POSITIVE'],
        ['X-ray result interpretation','X-RAY RESULT INTERPRETATION']
		  ],
      'tb_clinic_visit_type' => [
        ['',''],
        ['Lab analysis','Lab follow-up'],
        ['Follow-up','Follow-up'],
        ['Clinical review (Clinician visit)','Clinical review']
		  ],
      'family_planning_methods' => [
        ['',''],
        ['Oral contraceptive pills', 'ORAL CONTRACEPTIVE PILLS'],
        ['Depo-Provera', 'DEPO-PROVERA'],
        ['IUD-Intrauterine device/loop', 'INTRAUTERINE CONTRACEPTION'],
        ['Contraceptive implant', 'CONTRACEPTIVE IMPLANT'],
        ['Male condoms', 'MALE CONDOMS'],
        ['Female condoms', 'FEMALE CONDOMS'],
        ['Rhythm method', 'RYTHM METHOD'],
        ['Withdrawal', 'WITHDRAWAL'],
        ['Abstinence', 'ABSTINENCE'],
        ['Tubal ligation', 'TUBAL LIGATION'],
        ['Vasectomy', 'VASECTOMY']
		  ],
      'male_family_planning_methods' => [
        ['',''],
        ['Male condoms', 'MALE CONDOMS'],
        ['Withdrawal', 'WITHDRAWAL'],
        ['Rhythm method', 'RYTHM METHOD'],
        ['Abstinence', 'ABSTINENCE'],
        ['Vasectomy', 'VASECTOMY'],
        ['Other','OTHER']
		  ],
      'female_family_planning_methods' => [
        ['',''],
        ['Oral contraceptive pills', 'ORAL CONTRACEPTIVE PILLS'],
        ['Depo-Provera', 'DEPO-PROVERA'],
        ['IUD-Intrauterine device/loop', 'INTRAUTERINE CONTRACEPTION'],
        ['Contraceptive implant', 'CONTRACEPTIVE IMPLANT'],
        ['Female condoms', 'FEMALE CONDOMS'],
        ['Withdrawal', 'WITHDRAWAL'],
        ['Rhythm method', 'RYTHM METHOD'],
        ['Abstinence', 'ABSTINENCE'],
        ['Tubal ligation', 'TUBAL LIGATION'],
        ['Emergency contraception', 'EMERGENCY CONTRACEPTION'],
        ['Other','OTHER']
		  ],
      'drug_list' => [
			  ['',''],
			  ["Rifampicin Isoniazid Pyrazinamide and Ethambutol", "RHEZ (RIF, INH, Ethambutol and Pyrazinamide tab)"],
			  ["Rifampicin Isoniazid and Ethambutol", "RHE (Rifampicin Isoniazid and Ethambutol -1-1-mg t"],
			  ["Rifampicin and Isoniazid", "RH (Rifampin and Isoniazid tablet)"],
			  ["Stavudine Lamivudine and Nevirapine", "D4T+3TC+NVP"],
			  ["Stavudine Lamivudine + Stavudine Lamivudine and Nevirapine", "D4T+3TC/D4T+3TC+NVP"],
			  ["Zidovudine Lamivudine and Nevirapine", "AZT+3TC+NVP"]
		  ],
			'presc_time_period' => [
			  ["",""],
			  ["1 month", "30"],
			  ["2 months", "60"],
			  ["3 months", "90"],
			  ["4 months", "120"],
			  ["5 months", "150"],
			  ["6 months", "180"],
			  ["7 months", "210"],
			  ["8 months", "240"]
		  ],
			'continue_treatment' => [
			  ["",""],
			  ["Yes", "YES"],
			  ["DHO DOT site","DHO DOT SITE"],
			  ["Transfer Out", "TRANSFER OUT"]
		  ],
			'hiv_status' => [
			  ['',''],
			  ['Negative','NEGATIVE'],
			  ['Positive','POSITIVE'],
			  ['Unknown','UNKNOWN']
		  ],
		  'who_stage1' => [
        ['',''],
        ['Asymptomatic','ASYMPTOMATIC'],
        ['Persistent generalised lymphadenopathy','PERSISTENT GENERALISED LYMPHADENOPATHY'],
        ['Unspecified stage 1 condition','UNSPECIFIED STAGE 1 CONDITION']
		  ],
		  'who_stage2' => [
        ['',''],
        ['Unspecified stage 2 condition','UNSPECIFIED STAGE 2 CONDITION'],
        ['Angular cheilitis','ANGULAR CHEILITIS'],
        ['Popular pruritic eruptions / Fungal nail infections','POPULAR PRURITIC ERUPTIONS / FUNGAL NAIL INFECTIONS']
		  ],
		  'who_stage3' => [
        ['',''],
        ['Oral candidiasis','ORAL CANDIDIASIS'],
        ['Oral hairly leukoplakia','ORAL HAIRLY LEUKOPLAKIA'],
        ['Pulmonary tuberculosis','PULMONARY TUBERCULOSIS'],
        ['Unspecified stage 3 condition','UNSPECIFIED STAGE 3 CONDITION']
		  ],
		  'who_stage4' => [
        ['',''],
        ['Toxaplasmosis of the brain','TOXAPLASMOSIS OF THE BRAIN'],
        ["Kaposi's Sarcoma","KAPOSI'S SARCOMA"],
        ['Unspecified stage 4 condition','UNSPECIFIED STAGE 4 CONDITION'],
        ['HIV encephalopathy','HIV ENCEPHALOPATHY']
		  ],
		  'tb_xray_interpretation' => [
        ['',''],
        ['Consistent of TB','Consistent of TB'],
        ['Not Consistent of TB','Not Consistent of TB']
		  ],
		  'lab_orders' =>{
        "Blood" => ["Full blood count", "Malaria parasite", "Group & cross match", "Urea & Electrolytes", "CD4 count", "Resistance",
          "Viral Load", "Cryptococcal Antigen", "Lactate", "Fasting blood sugar", "Random blood sugar", "Sugar profile",
          "Liver function test", "Hepatitis test", "Sickling test", "ESR", "Culture & sensitivity", "Widal test", "ELISA",
          "ASO titre", "Rheumatoid factor", "Cholesterol", "Triglycerides", "Calcium", "Creatinine", "VDRL", "Direct Coombs",
          "Indirect Coombs", "Blood Test NOS"],
        "CSF" => ["Full CSF analysis", "Indian ink", "Protein & sugar", "White cell count", "Culture & sensitivity"],
        "Urine" => ["Urine microscopy", "Urinanalysis", "Culture & sensitivity"],
        "Aspirate" => ["Full aspirate analysis"],
        "Stool" => ["Full stool analysis", "Culture & sensitivity"],
        "Sputum-AAFB" => ["AAFB(1st)", "AAFB(2nd)", "AAFB(3rd)"],
        "Sputum-Culture" => ["Culture(1st)", "Culture(2nd)"],
        "Swab" => ["Microscopy", "Culture & sensitivity"]
		  },
		  'tb_symptoms_short' => [
        ['',''],
        ["Bloody cough", "Hemoptysis"],
        ["Chest pain", "Chest pain"],
        ["Cough", "Cough lasting more than three weeks"],
        ["Fatigue", "Fatigue"],
        ["Fever", "Relapsing fever"],
        ["Loss of appetite", "Loss of appetite"],
        ["Night sweats","Night sweats"],
        ["Shortness of breath", "Shortness of breath"],
        ["Weight loss", "Weight loss"],
        ["Other", "Other"]
		  ],
		  'tb_symptoms_all' => [
        ['',''],
        ["Bloody cough", "Hemoptysis"],
        ["Bronchial breathing", "Bronchial breathing"],
        ["Crackles", "Crackles"],
        ["Cough", "Cough lasting more than three weeks"],
        ["Failure to thrive", "Failure to thrive"],
        ["Fatigue", "Fatigue"],
        ["Fever", "Relapsing fever"],
        ["Loss of appetite", "Loss of appetite"],
        ["Meningitis", "Meningitis"],
        ["Night sweats","Night sweats"],
        ["Peripheral neuropathy", "Peripheral neuropathy"],
        ["Shortness of breath", "Shortness of breath"],
        ["Weight loss", "Weight loss"],
        ["Other", "Other"]
		  ],
		  'drug_related_side_effects' => [
        ['',''],
        ["Confusion", "Confusion"],
        ["Deafness", "Deafness"],
        ["Dizziness", "Dizziness"],
        ["Peripheral neuropathy","Peripheral neuropathy"],
        ["Skin itching/purpura", "Skin itching"],
        ["Visual impairment", "Visual impairment"],
        ["Vomiting", "Vomiting"],
        ["Yellow eyes", "Jaundice"],
        ["Other", "Other"]
		  ],
		  'tb_patient_categories' => [
        ['',''],
        ["New", "New patient"],
        ["Failure", "Failed - TB"],
        ["Relapse", "Relapse MDR-TB patient"],
        ["Treatment after default", "Treatment after default MDR-TB patient"],
        ["Other", "Other"]
		  ],
		  'duration_of_current_cough' => [
        ['',''],
        ["Less than 1 week", "Less than one week"],
        ["1 Week", "1 week"],
        ["2 Weeks", "2 weeks"],
        ["3 Weeks", "3 weeks"],
        ["4 Weeks", "4 weeks"],
        ["More than 4 Weeks", "More than 4 weeks"],
        ["Unknown", "Unknown"]
		  ],
		  'eptb_classification'=> [
        ['',''],
        ['Pulmonary effusion', 'Pulmonary effusion'],
        ['Lymphadenopathy', 'Lymphadenopathy'],
        ['Pericardial effusion', 'Pericardial effusion'],
        ['Ascites', 'Ascites'],
        ['Spinal disease', 'Spinal disease'],
        ['Meningitis','Meningitis'],
        ['Other', 'Other']
		  ],
		  'tb_types' => [
        ['',''],
        ['Susceptible', 'Susceptible to tuberculosis drug'],
        ['Multi-drug resistant (MDR)', 'Multi-drug resistant tuberculosis'],
        ['Extreme drug resistant (XDR)', 'Extreme drug resistant tuberculosis']
		  ],
		  'tb_classification' => [
        ['',''],
        ['Pulmonary tuberculosis (PTB)', 'Pulmonary tuberculosis'],
        ['Extrapulmonary tuberculosis (EPTB)', 'Extrapulmonary tuberculosis (EPTB)']
		  ],
		  'source_of_referral' => [
        ['',''],
        ['Walk in', 'Walk in'],
        ['Healthy Facility', 'Healthy Facility'],
        ['Index Patient', 'Index Patient'],
        ['HTC', 'HTC clinic'],
        ['ART', 'ART'],
        ['PMTCT', 'PMTCT'],
        ['Private practitioner', 'Private practitioner'],
        ['Sputum collection point', 'Sputum collection point'],
        ['Other','Other']
		  ]
		}
	end

	def create_adult_influenza_entry
		create_influenza_data
	end
  
	def create_influenza_data
		# raise params.to_yaml

		encounter = Encounter.new(params[:encounter])
		encounter.encounter_datetime = session[:datetime] unless session[:datetime].blank? or encounter.name == 'DIABETES TEST'
		encounter.save

		(params[:observations] || []).each { | observation |
			# Check to see if any values are part of this observation
			# This keeps us from saving empty observations
			values = "coded_or_text group_id boolean coded drug datetime numeric modifier text".split(" ").map { | value_name |
				observation["value_#{value_name}"] unless observation["value_#{value_name}"].blank? rescue nil
			}.compact

			next if values.length == 0
			observation.delete(:value_text) unless observation[:value_coded_or_text].blank?
			observation[:encounter_id] = encounter.id
			observation[:obs_datetime] = encounter.encounter_datetime ||= (session[:datetime] ||= Time.now())
			observation[:person_id] ||= encounter.patient_id
			observation[:concept_name] ||= "OUTPATIENT DIAGNOSIS" if encounter.type.name == "OUTPATIENT DIAGNOSIS"

			if(observation[:measurement_unit])
				observation[:value_numeric] = observation[:value_numeric].to_f * 18 if ( observation[:measurement_unit] == "mmol/l")
				observation.delete(:measurement_unit)
			end

			if(observation[:parent_concept_name])
				concept_id = Concept.find_by_name(observation[:parent_concept_name]).id rescue nil
				observation[:obs_group_id] = Observation.find(:first, :conditions=> ['concept_id = ? AND encounter_id = ?',concept_id, encounter.id]).id rescue ""
				observation.delete(:parent_concept_name)
			end

			extracted_value_numerics = observation[:value_numeric]
			if (extracted_value_numerics.class == Array)
				extracted_value_numerics.each do |value_numeric|
					observation[:value_numeric] = value_numeric
					Observation.create(observation)
				end
			else
				Observation.create(observation)
			end
		}
		@patient = Patient.find(params[:encounter][:patient_id])

		# redirect to a custom destination page 'next_url'
		if(params[:next_url])
			redirect_to params[:next_url] and return
		else
			redirect_to next_task(@patient)
		end
	end

	def create_influenza_recruitment
		create_influenza_data
	end
  
	# create_chronics is a method to save the results of an influenza
	# Chronic Conditions question set
	def create_chronics
		create_influenza_data
	end

	def presenting_complaints
		search_string = (params[:search_string] || '').upcase
		filter_list = params[:filter_list].split(/, */) rescue []
		
		presenting_complaint = ConceptName.find_by_name("PRESENTING COMPLAINT").concept
		

		complaint_set = CoreService.get_global_property_value("application_presenting_complaint")
		complaint_set = "PRESENTING COMPLAINT" if complaint_set.blank?
		complaint_concept_set = ConceptName.find_by_name(complaint_set).concept
		complaint_concepts = Concept.find(:all, :joins => :concept_sets, :conditions => ['concept_set = ?', complaint_concept_set.id])

		valid_answers = complaint_concepts.map{|concept| 
			name = concept.fullname rescue nil
			name.upcase.include?(search_string) ? name : nil rescue nil
		}.compact

		previous_answers = []

		# TODO Need to check global property to find out if we want previous answers or not (right now we)
		previous_answers = Observation.find_most_common(presenting_complaint, search_string)

		@suggested_answers = (previous_answers + valid_answers.sort!).reject{|answer| filter_list.include?(answer) }.uniq[0..10] 
		@suggested_answers = @suggested_answers - params[:search_filter].split(',') rescue @suggested_answers
		render :text => "<li></li>" + "<li>" + @suggested_answers.join("</li><li>") + "</li>"
	end

	#added this to ensure that we are able to get the detailed diagnosis set
	def diagnosis_details
		concept_name = params[:diagnosis_string]
		options = concept_set(concept_name).flatten.uniq
		render :text => "<li></li><li>" + options.join("</li><li>") + "</li>"
	end

	#added this to ensure that we are able to get the detailed concept set
	def concept_options
		concept_name = params[:search_string]
		options = concept_set(concept_name).flatten.uniq

		render :text => "<li></li><li>" + options.join("</li><li>") + "</li>"
	end

=begin
	def is_first_art_visit(patient_id)
		     session_date = session[:datetime].to_date rescue Date.today
		     art_encounter = Encounter.find(:first,:conditions =>["voided = 0 AND patient_id = ? AND encounter_type = ? AND DATE(encounter_datetime) < ?",
		                     patient_id, EncounterType.find_by_name('ART_INITIAL').id, session_date ]) rescue nil
		    return true if art_encounter.nil?
		     return false
	end
=end


  def life_threatening_condition  
    search_string = (params[:search_string] || '').upcase
    
    aconcept_set = []
        
    common_answers = Observation.find_most_common(ConceptName.find_by_name("Life threatening condition").concept, search_string)
    concept_set("Life threatening condition").each{|concept| aconcept_set << concept.uniq.to_s rescue "test"}  
    set = (common_answers + aconcept_set.sort).uniq             
    set.map!{|cc| cc.upcase.include?(search_string)? cc : nil}        
    
    set = set.sort rescue []
           
    render :text => "<li></li>" + "<li>" + set.join("</li><li>") + "</li>"

  end

  def triage_category

    search_string = (params[:search_string] || '').upcase   
    aconcept_set = []        

    common_answers = Observation.find_most_common(ConceptName.find_by_name("Triage category").concept, search_string)
    concept_set("Triage category").each{|concept| aconcept_set << concept.uniq.to_s rescue "test"}  
    set = (common_answers + aconcept_set.sort).uniq
    set.map!{|cc| cc.upcase.include?(search_string)? cc : nil}
             
    set = set.sort rescue []
           
    render :text => "<li></li>" + "<li>" + set.join("</li><li>") + "</li>"
  end


  def create_complaints
      encounter = Encounter.new()
      if params['encounter']['encounter_type_name'].upcase == 'NOTES'
        encounter.encounter_type = EncounterType.find_by_name("NOTES").id
      else
        encounter.encounter_type = EncounterType.find_by_name("VITALS").id
      end
      encounter.patient_id = params['encounter']['patient_id']
      encounter.encounter_datetime = session[:datetime]
      if params[:filter] and !params[:filter][:provider].blank?
        user_person_id = User.find_by_username(params[:filter][:provider]).person_id
      else
        user_person_id = User.find_by_user_id(params['encounter']['provider_id']).person_id
      end
      encounter.provider_id = user_person_id
      encounter.save

      (params[:complaints] || []).each do |complaint|
      encounter_id = Encounter.find(:last, :order => 'encounter_id ASC').id
		  if !complaint.blank?
        multiple = complaint.match(/[:]/)
        unless multiple.nil?
          multiple_array = complaint.split(":")
          concept_name = ConceptName.find_by_name(multiple_array[0]).name
          parent_obs = {
            "encounter_id" => "#{encounter_id}",
            "patient_id" => params['encounter']['patient_id'],
            "concept_name" => "#{concept_name}".upcase,
            "value_text" => "#{multiple_array[0]}",
            "obs_datetime" => params['encounter']['encounter_datetime']
          }

          b = Observation.create(parent_obs)
          encounter_id = b.encounter_id
          parent_concept_id = b.concept_id
          obs_group = Observation.find(:first, :order => "obs_id DESC", :conditions => ["encounter_id =? AND concept_id =?", \
                    encounter_id, parent_concept_id])
          obs_group_id = obs_group.id if obs_group
          child_obs = {
            "encounter_id" => "#{encounter_id}",
            "patient_id" => params['encounter']['patient_id'],
            "concept_name" => "#{multiple_array[0]}",
            "value_text" => "#{multiple_array[1]}",
            "obs_group_id" => "#{obs_group_id}",
            "obs_datetime" => params['encounter']['encounter_datetime']
          }
         Observation.create(child_obs)
        else
          obs = {
            "encounter_id" => "#{encounter.id}",
            "patient_id" => params['encounter']['patient_id'],
						"concept_name" => "#{complaint}".upcase,
						"value_text" => complaint,
						"obs_datetime" => params['encounter']['encounter_datetime']
          }
          Observation.create(obs)
        end
		  end
    end
   create_obs(encounter, params)
   @patient_id = params[:encounter][:patient_id]
   redirect_to("/patients/show/#{@patient_id}")
  end

  def recorded_religions                                                        
    religions = Observation.find(:all, :joins => [:concept, :encounter],         
      :conditions => ["obs.concept_id = ? 
      AND value_text LIKE '%#{params[:search_string]}%' AND encounter_type = ?",                                                
      ConceptName.find_by_name("Other").concept_id,                           
      EncounterType.find_by_name("SOCIAL HISTORY").id]).collect{|o| o.value_text}
                                                                                
    result = "<li>" + religions.map{|n| n } .join("</li><li>") + "</li>"        
    render :text => result                                                      
  end

	def require_temtct_registration(patient_obj = nil)
		require_registration = false
		patient = patient_obj || find_patient

		temtct_registration = Encounter.find(:first,:conditions =>["patient_id = ? 
		              AND encounter_type = ?",patient.id,
		              EncounterType.find_by_name("TEMTCT REGISTRATION").id],
		              :order =>'encounter_datetime DESC,date_created DESC')

		require_registration = true if temtct_registration.blank?
	
		return require_registration
	end


  def create(params=params, session=session)

    if params[:change_appointment_date] == "true"
      session_date = session[:datetime].to_date rescue Date.today
      type = EncounterType.find_by_name("APPOINTMENT")                            
      appointment_encounter = Observation.find(:first,                            
      :order => "encounter_datetime DESC,encounter.date_created DESC",
      :joins => "INNER JOIN encounter ON obs.encounter_id = encounter.encounter_id",
      :conditions => ["concept_id = ? AND encounter_type = ? AND patient_id = ?
      AND encounter_datetime >= ? AND encounter_datetime <= ?",
      ConceptName.find_by_name('Appointment date').concept_id,
      type.id, params[:encounter]["patient_id"],session_date.strftime("%Y-%m-%d 00:00:00"),             
      session_date.strftime("%Y-%m-%d 23:59:59")]).encounter
      appointment_encounter.void("Given a new appointment date")
    end
    	
    if params['encounter']['encounter_type_name'] == 'TB_INITIAL'
      (params[:observations] || []).each do |observation|
        if observation['concept_name'].upcase == 'TRANSFER IN' and observation['value_coded_or_text'] == "YES"
          params[:observations] << {"concept_name" => "TB STATUS","value_coded_or_text" => "Confirmed TB on treatment"}
        end
      end
    end

    if params['encounter']['encounter_type_name'] == 'HIV_CLINIC_REGISTRATION'

      has_tranfer_letter = false
      (params["observations"]).each do |ob|
        if ob["concept_name"] == "HAS TRANSFER LETTER" 
          has_tranfer_letter = (ob["value_coded_or_text"].upcase == "YES")
          break
        end
      end
      
      if params[:observations][0]['concept_name'].upcase == 'EVER RECEIVED ART' and params[:observations][0]['value_coded_or_text'].upcase == 'NO'
        observations = []
        (params[:observations] || []).each do |observation|
          next if observation['concept_name'].upcase == 'HAS TRANSFER LETTER'
          next if observation['concept_name'].upcase == 'HAS THE PATIENT TAKEN ART IN THE LAST TWO WEEKS'
          next if observation['concept_name'].upcase == 'HAS THE PATIENT TAKEN ART IN THE LAST TWO MONTHS'
          next if observation['concept_name'].upcase == 'ART NUMBER AT PREVIOUS LOCATION'
          next if observation['concept_name'].upcase == 'DATE ART LAST TAKEN'
          next if observation['concept_name'].upcase == 'LAST ART DRUGS TAKEN'
          next if observation['concept_name'].upcase == 'TRANSFER IN'
          next if observation['concept_name'].upcase == 'HAS THE PATIENT TAKEN ART IN THE LAST TWO WEEKS'
          next if observation['concept_name'].upcase == 'HAS THE PATIENT TAKEN ART IN THE LAST TWO MONTHS'
          observations << observation
        end
      elsif params[:observations][4]['concept_name'].upcase == 'DATE ART LAST TAKEN' and params[:observations][4]['value_datetime'] != 'Unknown'
        observations = []
        (params[:observations] || []).each do |observation|
          next if observation['concept_name'].upcase == 'HAS THE PATIENT TAKEN ART IN THE LAST TWO WEEKS'
          next if observation['concept_name'].upcase == 'HAS THE PATIENT TAKEN ART IN THE LAST TWO MONTHS'
          observations << observation
        end
      end

      params[:observations] = observations unless observations.blank?

      observations = []
      (params[:observations] || []).each do |observation|
        if observation['concept_name'].upcase == 'LOCATION OF ART INITIATION' or observation['concept_name'].upcase == 'CONFIRMATORY HIV TEST LOCATION'
          observation['value_numeric'] = observation['value_coded_or_text'] rescue nil
          observation['value_text'] = Location.find(observation['value_coded_or_text']).name.to_s rescue ""
          observation['value_coded_or_text'] = ""
        end
        observations << observation
      end

      params[:observations] = observations unless observations.blank?

      observations = []
      vitals_observations = []
      initial_observations = []
      (params[:observations] || []).each do |observation|
        if observation['concept_name'].upcase == 'WHO STAGES CRITERIA PRESENT'
          observations << observation
        elsif observation['concept_name'].upcase == 'WHO STAGES CRITERIA PRESENT'
          observations << observation
        elsif observation['concept_name'].upcase == 'CD4 COUNT LOCATION'
          observations << observation
        elsif observation['concept_name'].upcase == 'CD4 COUNT DATETIME'
          observations << observation
        elsif observation['concept_name'].upcase == 'CD4 COUNT'
          observations << observation
        elsif observation['concept_name'].upcase == 'CD4 COUNT LESS THAN OR EQUAL TO 250'
          observations << observation
        elsif observation['concept_name'].upcase == 'CD4 COUNT LESS THAN OR EQUAL TO 350'
          observations << observation
        elsif observation['concept_name'].upcase == 'CD4 PERCENT'
          observations << observation
        elsif observation['concept_name'].upcase == 'CD4 PERCENT LESS THAN 25'
          observations << observation
        elsif observation['concept_name'].upcase == 'REASON FOR ART ELIGIBILITY'
          observations << observation
        elsif observation['concept_name'].upcase == 'WHO STAGE'
          observations << observation
        elsif observation['concept_name'].upcase == 'BODY MASS INDEX, MEASURED'
          bmi = nil
          (params["observations"]).each do |ob|
            if ob["concept_name"] == "BODY MASS INDEX, MEASURED" 
              bmi = ob["value_numeric"]
              break
            end
          end
          next if bmi.blank? 
          vitals_observations << observation
        elsif observation['concept_name'].upcase == 'WEIGHT (KG)'
          weight = 0
          (params["observations"]).each do |ob|
            if ob["concept_name"] == "WEIGHT (KG)" 
              weight = ob["value_numeric"].to_f rescue 0
              break
            end
          end
          next if weight.blank? or weight < 1
          vitals_observations << observation
        elsif observation['concept_name'].upcase == 'HEIGHT (CM)'
          height = 0
          (params["observations"]).each do |ob|
            if ob["concept_name"] == "HEIGHT (CM)" 
              height = ob["value_numeric"].to_i rescue 0
              break
            end
          end
          next if height.blank? or height < 1
          vitals_observations << observation
        else
          initial_observations << observation
        end
      end if has_tranfer_letter

      date_started_art = nil
      (initial_observations || []).each do |ob|
        if ob['concept_name'].upcase == 'DATE ANTIRETROVIRALS STARTED'
          date_started_art = ob["value_datetime"].to_date rescue nil
          if date_started_art.blank?
            date_started_art = ob["value_coded_or_text"].to_date rescue nil
          end
        end
      end
      
      unless vitals_observations.blank?
        encounter = Encounter.new()
        encounter.encounter_type = EncounterType.find_by_name("VITALS").id
        encounter.patient_id = params['encounter']['patient_id']
        encounter.encounter_datetime = date_started_art 
        if encounter.encounter_datetime.blank?                                                                        
          encounter.encounter_datetime = params['encounter']['encounter_datetime']  
        end 
        if params[:filter] and !params[:filter][:provider].blank?
          user_person_id = User.find_by_username(params[:filter][:provider]).person_id
        else
          user_person_id = User.find_by_user_id(params['encounter']['provider_id']).person_id
        end
        encounter.provider_id = user_person_id
        encounter.save   
        params[:observations] = vitals_observations
        create_obs(encounter , params)
      end

      unless observations.blank? 
        encounter = Encounter.new()
        encounter.encounter_type = EncounterType.find_by_name("HIV STAGING").id
        encounter.patient_id = params['encounter']['patient_id']
        encounter.encounter_datetime = date_started_art 
        if encounter.encounter_datetime.blank?                                                                        
          encounter.encounter_datetime = params['encounter']['encounter_datetime']  
        end 
        if params[:filter] and !params[:filter][:provider].blank?
          user_person_id = User.find_by_username(params[:filter][:provider]).person_id
        else
          user_person_id = User.find_by_user_id(params['encounter']['provider_id']).person_id
        end
        encounter.provider_id = user_person_id
        encounter.save 
          
        params[:observations] = observations 

        (params[:observations] || []).each do |observation|
          if observation['concept_name'].upcase == 'CD4 COUNT' or observation['concept_name'].upcase == "LYMPHOCYTE COUNT"
            observation['value_modifier'] = observation['value_numeric'].match(/=|>|</i)[0] rescue nil
            observation['value_numeric'] = observation['value_numeric'].match(/[0-9](.*)/i)[0] rescue nil
          end
        end
        create_obs(encounter , params)
      end
      params[:observations] = initial_observations if has_tranfer_letter  
    end

    if params['encounter']['encounter_type_name'].upcase == 'HIV STAGING'
      observations = []
      (params[:observations] || []).each do |observation|
        if observation['concept_name'].upcase == 'CD4 COUNT' or observation['concept_name'].upcase == "LYMPHOCYTE COUNT"
          observation['value_modifier'] = observation['value_numeric'].match(/=|>|</i)[0] rescue nil
          observation['value_numeric'] = observation['value_numeric'].match(/[0-9](.*)/i)[0] rescue nil
        end
        if observation['concept_name'].upcase == 'CD4 COUNT LOCATION' or observation['concept_name'].upcase == 'LYMPHOCYTE COUNT LOCATION'
          observation['value_numeric'] = observation['value_coded_or_text'] rescue nil
          observation['value_text'] = Location.find(observation['value_coded_or_text']).name.to_s rescue ""
          observation['value_coded_or_text'] = ""
        end
        if observation['concept_name'].upcase == 'CD4 PERCENT LOCATION'
          observation['value_numeric'] = observation['value_coded_or_text'] rescue nil
          observation['value_text'] = Location.find(observation['value_coded_or_text']).name.to_s rescue ""
          observation['value_coded_or_text'] = ""
        end

        observations << observation
      end
      
      params[:observations] = observations unless observations.blank?
    end

    if params['encounter']['encounter_type_name'].upcase == 'ART ADHERENCE'
      previous_hiv_clinic_consultation_observations = []
      art_adherence_observations = []
      (params[:observations] || []).each do |observation|
        if observation['concept_name'].upcase == 'REFER TO ART CLINICIAN'
          previous_hiv_clinic_consultation_observations << observation
        elsif observation['concept_name'].upcase == 'PRESCRIBE DRUGS'
          previous_hiv_clinic_consultation_observations << observation
        elsif observation['concept_name'].upcase == 'ALLERGIC TO SULPHUR'
          previous_hiv_clinic_consultation_observations << observation
        else
          art_adherence_observations << observation
        end
      end

      unless previous_hiv_clinic_consultation_observations.blank?
        #if "REFER TO ART CLINICIAN","PRESCRIBE DRUGS" and "ALLERGIC TO SULPHUR" has
        #already been asked during HIV CLINIC CONSULTATION - we append the observations to the latest 
        #HIV CLINIC CONSULTATION encounter done on that day

        session_date = session[:datetime].to_date rescue Date.today
        encounter_type = EncounterType.find_by_name("HIV CLINIC CONSULTATION")
        encounter = Encounter.find(:first,:order =>"encounter_datetime DESC,date_created DESC",
          :conditions =>["encounter_type=? AND patient_id=? AND encounter_datetime >= ?
          AND encounter_datetime <= ?",encounter_type.id,params['encounter']['patient_id'],
          session_date.strftime("%Y-%m-%d 00:00:00"),session_date.strftime("%Y-%m-%d 23:59:59")])
        if encounter.blank?
          encounter = Encounter.new()
          encounter.encounter_type = encounter_type.id
          encounter.patient_id = params['encounter']['patient_id']
          encounter.encounter_datetime = session_date.strftime("%Y-%m-%d 00:00:01")
          if params[:filter] and !params[:filter][:provider].blank?
            user_person_id = User.find_by_username(params[:filter][:provider]).person_id
          else
            user_person_id = User.find_by_user_id(params['encounter']['provider_id']).person_id
          end
          encounter.provider_id = user_person_id
          encounter.save   
        end 
        params[:observations] = previous_hiv_clinic_consultation_observations
        create_obs(encounter , params)
      end

      params[:observations] = art_adherence_observations

      observations = []
      (params[:observations] || []).each do |observation|
        if observation['concept_name'].upcase == 'WHAT WAS THE PATIENTS ADHERENCE FOR THIS DRUG ORDER'
          observation['value_numeric'] = observation['value_text'] rescue nil
          observation['value_text'] =  ""
        end

        if observation['concept_name'].upcase == 'MISSED HIV DRUG CONSTRUCT'
          observation['value_numeric'] = observation['value_coded_or_text'] rescue nil
          observation['value_coded_or_text'] = ""
        end
        observations << observation
      end
      params[:observations] = observations unless observations.blank?
    end

   if params['encounter']['encounter_type_name'].upcase == 'REFER PATIENT OUT?'
      observations = []
      (params[:observations] || []).each do |observation|
        if observation['concept_name'].upcase == 'REFERRAL CLINIC IF REFERRED'
          observation['value_numeric'] = observation['value_coded_or_text'] rescue nil
          observation['value_text'] = Location.find(observation['value_coded_or_text']).name.to_s rescue ""
          observation['value_coded_or_text'] = ""
        end

        observations << observation
      end

      params[:observations] = observations unless observations.blank?
    end

    @patient = Patient.find(params[:encounter][:patient_id]) rescue nil
    if params[:location]
      if @patient.nil?
        @patient = Patient.find_with_voided(params[:encounter][:patient_id])
      end

      Person.migrated_datetime = params['encounter']['date_created']
      Person.migrated_creator  = params['encounter']['creator'] rescue nil

      # set current location via params if given
      Location.current_location = Location.find(params[:location])
    end
    
    if params['encounter']['encounter_type_name'].to_s.upcase == "APPOINTMENT" && !params[:report_url].nil? && !params[:report_url].match(/report/).nil?
        concept_id = ConceptName.find_by_name("RETURN VISIT DATE").concept_id
        encounter_id_s = Observation.find_by_sql("SELECT encounter_id
                       FROM obs
                       WHERE concept_id = #{concept_id} AND person_id = #{@patient.id}
                            AND DATE(value_datetime) = DATE('#{params[:old_appointment]}') AND voided = 0
                       ").map{|obs| obs.encounter_id}.each do |encounter_id|
                                    Encounter.find(encounter_id).void
                       end   
    end

    # Encounter handling
		encounter = Encounter.new(params[:encounter])
		unless params[:location]
		  encounter.encounter_datetime = session[:datetime] unless session[:datetime].blank?
		else
		  encounter.encounter_datetime = params['encounter']['encounter_datetime']
		end

		if params[:filter] and !params[:filter][:provider].blank?
		  user_person_id = User.find_by_username(params[:filter][:provider]).person_id
		elsif params[:location] # Migration
		  user_person_id = encounter[:provider_id]
		else
		  user_person_id = User.find_by_user_id(encounter[:provider_id]).person_id
		end
		encounter.provider_id = user_person_id

		encounter.save

    #create observations for the just created encounter
    create_obs(encounter , params)

		if !params[:recalculate_bmi].blank? && params[:recalculate_bmi] == "true"
				weight = 0
				height = 0

				weight_concept_id  = ConceptName.find_by_name("Weight (kg)").concept_id
				height_concept_id  = ConceptName.find_by_name("Height (cm)").concept_id
				bmi_concept_id = ConceptName.find_by_name("Body mass index, measured").concept_id
				work_station_concept_id = ConceptName.find_by_name("Workstation location").concept_id
				
				vitals_encounter_id = EncounterType.find_by_name("VITALS").encounter_type_id
				enc = Encounter.find(:all, :conditions => ["encounter_type = ? AND patient_id = ?
											AND voided=0", vitals_encounter_id, @patient.id])

				encounter.observations.each do |o|
							height = o.answer_string.squish if o.concept_id == height_concept_id 
				end
								
				enc.each do |e|
						obs_created = false
						weight = nil
						
						e.observations.each do |o|
							next if o.concept_id == work_station_concept_id
							
							if o.concept_id == weight_concept_id
								weight = o.answer_string.squish.to_i
							elsif o.concept_id == height_concept_id || o.concept_id == bmi_concept_id
								o.voided = 1
								o.date_voided = Time.now
								o.voided_by = encounter.creator
								o.void_reason = "Back data entry recalculation"
								o.save
							end
						end

						bmi = (weight.to_f/(height.to_f*height.to_f)*10000).round(1) rescue "Unknown"

						field = :value_numeric
						field = :value_text and height = 'Unknown' if height == 'Unknown' || height.to_i == 0

						height_obs = Observation.new(
							:concept_name => "Height (cm)",
							:person_id => @patient.id,
							:encounter_id => e.id,
							field => height,
							:obs_datetime => e.encounter_datetime)

						height_obs.save
						
						field = :value_numeric
						field = :value_text and bmi = 'Unknown' if bmi == 'Unknown' || bmi.to_i == 0
												
						bmi_obs = Observation.new(
							:concept_name => "Body mass index, measured",
							:person_id => @patient.id,
							:encounter_id => e.id,
							field => bmi,
							:obs_datetime => e.encounter_datetime)

						bmi_obs.save
				end
		end
		
		if params['encounter']['encounter_type_name'].upcase == 'TEMTCT REGISTRATION'
			valid_program = false			
			observations = []
			(params[:observations] || []).each do |observation|
				if observation['concept_name'].upcase == 'SIGNED CONSENT FORM' && observation['value_coded'] == 1065
					valid_program = true
				end

				if observation['concept_name'].upcase == 'BREAST FEEDING'
					valid_program = true
				end

			end
			
			if valid_program == false
				params[:programs] = nil
			end

		end





    # Program handling
    date_enrolled = params[:programs][0]['date_enrolled'].to_time rescue nil
    date_enrolled = session[:datetime] || Time.now() if date_enrolled.blank?
    (params[:programs] || []).each do |program|
      # Look up the program if the program id is set      
      @patient_program = PatientProgram.find(program[:patient_program_id]) unless program[:patient_program_id].blank?

      #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
      #if params[:location] is not blank == migration params
      if params[:location]
        next if not @patient.patient_programs.in_programs("HIV PROGRAM").blank?
      end
      #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

      # If it wasn't set, we need to create it
      unless (@patient_program)
        @patient_program = @patient.patient_programs.create(
          :program_id => program[:program_id],
          :date_enrolled => date_enrolled)          
      end
      # Lots of states bub
      unless program[:states].blank?
        #adding program_state start date
        program[:states][0]['start_date'] = date_enrolled
      end
      (program[:states] || []).each {|state| @patient_program.transition(state) }
    end

    # Identifier handling
    arv_number_identifier_type = PatientIdentifierType.find_by_name('ARV Number').id
    (params[:identifiers] || []).each do |identifier|
      # Look up the identifier if the patient_identfier_id is set      
      @patient_identifier = PatientIdentifier.find(identifier[:patient_identifier_id]) unless identifier[:patient_identifier_id].blank?
      # Create or update
      type = identifier[:identifier_type].to_i rescue nil
      unless (arv_number_identifier_type != type) and @patient_identifier
        arv_number = identifier[:identifier].strip
        if arv_number.match(/(.*)[A-Z]/i).blank?
          if params['encounter']['encounter_type_name'] == 'TB REGISTRATION'
            identifier[:identifier] = "#{PatientIdentifier.site_prefix}-TB-#{arv_number}"
          else
            identifier[:identifier] = "#{PatientIdentifier.site_prefix}-ARV-#{arv_number}"
          end
        end
      end

      if @patient_identifier
        @patient_identifier.update_attributes(identifier)      
      else
        @patient_identifier = @patient.patient_identifiers.create(identifier)
      end
    end

    # person attribute handling
    (params[:person] || []).each do | type , attribute |
      # Look up the attribute if the person_attribute_id is set  

      #person_attribute_id = person_attribute[:person_attribute_id].to_i rescue nil    
      @person_attribute = nil #PersonAttribute.find(person_attribute_id) unless person_attribute_id.blank?
      # Create or update

      if not @person_attribute.blank?
        @patient_identifier.update_attributes(person_attribute)      
      else
        case type
          when 'agrees_to_be_visited_for_TB_therapy'
            @person_attribute = @patient.person.person_attributes.create(
            :person_attribute_type_id => PersonAttributeType.find_by_name("Agrees to be visited at home for TB therapy").person_attribute_type_id,
            :value => attribute)
          when 'agrees_phone_text_for_TB_therapy'
            @person_attribute = @patient.person.person_attributes.create(
            :person_attribute_type_id => PersonAttributeType.find_by_name("Agrees to phone text for TB therapy").person_attribute_type_id,
            :value => attribute)
        end
      end
    end

    # if params['encounter']['encounter_type_name'] == "APPOINTMENT"
    #  redirect_to "/patients/treatment_dashboard/#{@patient.id}" and return
    # else
      # Go to the dashboard if this is a non-encounter
      # redirect_to "/patients/show/#{@patient.id}" unless params[:encounter]
      # redirect_to next_task(@patient)
    # end

    # Go to the next task in the workflow (or dashboard)
    # only redirect to next task if location parameter has not been provided

    
    unless params[:location]
    #find a way of printing the lab_orders labels
     if params['encounter']['encounter_type_name'] == "LAB ORDERS"
       redirect_to"/patients/print_lab_orders/?patient_id=#{@patient.id}"
     elsif params['encounter']['encounter_type_name'] == "TB suspect source of referral" && !params[:gender].empty? && !params[:family_name].empty? && !params[:given_name].empty?
       redirect_to"/encounters/new/tb_suspect_source_of_referral/?patient_id=#{@patient.id}&gender=#{params[:gender]}&family_name=#{params[:family_name]}&given_name=#{params[:given_name]}"
     else
      if params['encounter']['encounter_type_name'].to_s.upcase == "APPOINTMENT" && !params[:report_url].nil? && !params[:report_url].match(/report/).nil?
         redirect_to  params[:report_url].to_s and return
      elsif params['encounter']['encounter_type_name'].upcase == 'APPOINTMENT'
        print_and_redirect("/patients/dashboard_print_visit/#{params[:encounter]['patient_id']}","/patients/show/#{params[:encounter]['patient_id']}")
        return
      end

		# Remove session date and redirect to next task
		session[:datetime] = nil
		redirect_to next_task(@patient)
     end
    else
      if params[:voided]
        encounter.void(params[:void_reason],
                       params[:date_voided],
                       params[:voided_by])
      end
      #made restful the default due to time
      render :text => encounter.encounter_id.to_s and return
      #return encounter.id.to_s  # support non-RESTful creation of encounters
    end
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
		weight = 23
		if @patient_is_child_bearing_female
			weight = 60
		end
		

		my_drugs = temtct_arv_drugs.map { |t| t.concept_id }


		regimens = Regimen.find(	:all,
									:order => 'regimen_index',
									:conditions => ['? >= min_weight AND ? < max_weight AND concept_id IN (?)', weight, weight, my_drugs])
		
		
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


end
