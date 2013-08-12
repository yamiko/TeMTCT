class ApplicationController < GenericApplicationController
COMMON_YEAR_DAYS_IN_MONTH = [nil, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
helper_method :allowed_hiv_viewer
  def next_task(patient)
    session_date = session[:datetime].to_date rescue Date.today
    task = main_next_task(Location.current_location, patient, session_date)
    begin
      return task.url if task.present? && task.url.present?
      return "/patients/show/#{patient.id}" 
    rescue
      return "/patients/show/#{patient.id}" 
    end
  end

  # Try to find the next task for the patient at the given location
	def main_next_task(location, patient, session_date = Date.today)
		encounter_available = nil
		task = Task.first rescue nil
    	task = Task.new() if task.blank?
		
		task.encounter_type = 'NONE'
		task.url = "/patients/show/#{patient.id}"

		return task
	end
  
	def is_encounter_available(patient, encounter_type, session_date)
		is_vailable = false

		encounter_available = Encounter.find(:first,:conditions =>["patient_id = ? AND encounter_type = ? AND DATE(encounter_datetime) = ?",
						                           patient.id, EncounterType.find_by_name(encounter_type).id, session_date],
						                           :order =>'encounter_datetime DESC', :limit => 1)
		if encounter_available.blank?
			is_available = false
		else
			is_available = true
		end


		return is_available	
	end

	def encounter_available_ever(patientx, encounter_typex)
		is_vailable = false
		
		
		encounter_type_id = EncounterType.find_by_name(encounter_typex).id
		patient_id = patientx.id		

		encounter_available = Encounter.find(:first,:conditions =>["patient_id = ? AND encounter_type = ?",
						                           patient_id, encounter_type_id = EncounterType.find_by_name(encounter_typex).id],
						                           :order =>'encounter_datetime DESC', :limit => 1)

		if encounter_available.blank?
			is_available = false
		else
			is_available = true
		end

		return is_available	
	end

	def allowed_hiv_viewer
				allowed = false
				user_roles = current_user_roles.collect{|role| role.to_s.upcase}
				if user_roles.include?("DOCTOR") || user_roles.include?("NURSE") || user_roles.include?("SUPERUSER")
						allowed = true
				end
  end 	
  
  def hiv_program
  	program = PatientProgram.first(:conditions => {:patient_id => @patient.id,
      :program_id => Program.find_by_name('HIV PROGRAM').id}) rescue nil
    unless program.nil?
  	   return program.program_id
    else
       return false
    end
  end
  
  def remove_art_encounters(all_encounters, type)
    non_art_encounters = []
    hiv_encounters_list = [ "HIV STAGING", "HIV CLINIC REGISTRATION", 
                            "HIV RECEPTION","HIV CLINIC CONSULTATION",
                            "EXIT FROM HIV CARE","ART ADHERENCE",
                            "ART_FOLLOWUP","ART ENROLLMENT",
                            "UPDATE HIV STATUS","APPOINTMENT"
                          ]
    if type.to_s.downcase == 'encounter'
      all_encounters.each{|encounter|
        if ! hiv_encounters_list.include? EncounterType.find(encounter.encounter_type).name.to_s.upcase
          if encounter.encounter_type == EncounterType.find_by_name("Treatment").id || encounter.encounter_type == EncounterType.find_by_name("dispensing").id
            non_art_encounters << encounter if check_for_arvs_presence(encounter) != true       
          else
            non_art_encounters<< encounter
          end
        end
      }
    elsif type.to_s.downcase == 'prescription'
      arv_drugs = []
      concept_set("antiretroviral drugs").each{|concept| arv_drugs << concept.uniq.to_s}
      
      all_encounters.each{|prescription|
        if ! arv_drugs.include? Concept.find(prescription.concept_id).fullname
          non_art_encounters << prescription
        end
      }
    elsif type.to_s.downcase == 'program'
      hiv_program_id = Program.find_by_name('HIV program').id
      all_encounters.each{|program|
        if program.program_id != hiv_program_id
          non_art_encounters << program
        end
      }
    end
    
    return non_art_encounters
    
  end
  
  def days_in_month(month, year = Time.now.year)
   	return 29 if month == 2 && Date.gregorian_leap?(year)
   	COMMON_YEAR_DAYS_IN_MONTH[month]
  end
  
  def check_for_arvs_presence(encounter)
    arv_drugs = []
    concept_set("antiretroviral drugs").each{|concept| arv_drugs << concept.uniq.to_s}
    dispensed_id = Concept.find_by_name('Amount dispensed').concept_id
    arv_regimen_concept_id = Concept.find_by_name('Regimen Category').concept_id
    
    encounter.orders.each{|order|
      if ! arv_drugs.include? Concept.find(order.concept_id).fullname
        return true
      end  
    }
       
    encounter.observations.each {|obs|
      if obs.concept_id == dispensed_id
        return true if arv_drugs.include? Concept.find(Drug.find(obs.value_drug).concept_id).fullname
      elsif obs.concept_id == arv_regimen_concept_id
        return true
      end
    }

    return false
  end
  
end
