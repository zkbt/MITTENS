import os
from os import path
from itertools import izip
import shutil
from multiprocessing import Pool
from math import pi
import math
import csv
import operator
import pickle
import time
import gc
import datetime

import numpy as np
from scipy.optimize import leastsq

import pyfits
from pywcs import WCS
from ephem import Equatorial, Ecliptic

import matplotlib
# Force matplotlib to not use any Xwindows backend.
matplotlib.use('Agg')
import matplotlib.pyplot as plot


reset_everything = True

def main():
    if reset_everything:
        os.system('rm /data/mearth2/marples/*/Observation_List.txt')
        
    
    master_data_directories = ['/data/mearth2/2008-2010-iz/reduced/','/data/mearth2/2010-2011-I/','/data/mearth1/reduced/','/data/mearth2/south/reduced/']

    dummy_var = datetime.date.today()
    current_year = int(str(dummy_var)[0:4])

    #Create blank object catalog cause we have to go from OBJECT (lspm) to 2MASS
    ## dictionary_lspm_object = []
    ## dictionary_2mass_id_mdwarfs = []

    ## #hardcode some of these in
    ## dictionary_lspm_object.append('lspm1194')
    ## dictionary_2mass_id_mdwarfs.append(['17195422+2630030','17195298+2630026'])
    ## dictionary_lspm_object.append('lspm315')
    ## dictionary_2mass_id_mdwarfs.append(['04311147+5858375'])
    ## dictionary_lspm_object.append('lspm2603')
    ## dictionary_2mass_id_mdwarfs.append(['01532823+7329424','01532600+7330177'])
    ## dictionary_lspm_object.append('lspm1329')
    ## dictionary_2mass_id_mdwarfs.append(['19143925+1919025','19143932+1918219'])
    ## dictionary_lspm_object.append('lspm2771')
    ## dictionary_2mass_id_mdwarfs.append(['04074393+1413246','04075479+1413006'])
    ## dictionary_lspm_object.append('lspm1322lspm2331')
    ## dictionary_2mass_id_mdwarfs.append(['19074283+3232396','19082996+3216520'])
    ## dictionary_lspm_object.append('lspm1984')
    ## dictionary_2mass_id_mdwarfs.append(['08585633+0828259'])
    ## dictionary_lspm_object.append('lspm3682')
    ## dictionary_2mass_id_mdwarfs.append(['18132818+0526583'])
    ## dictionary_lspm_object.append('lspm1320')
    ## dictionary_2mass_id_mdwarfs.append(['19071320+2052372','19070556+2053168'])
    ## dictionary_lspm_object.append('lspm3810')
    ## dictionary_2mass_id_mdwarfs.append(['19535295+7501411','19535003+7501299'])

    (dictionary_lspm_object,dictionary_2mass_id_mdwarfs) = pickle.load( open("the_dictionary.pickle","rb") )

    #dictionary_lspm_object.append('lspm2371')
    #dictionary_2mass_id_mdwarfs.append(['21011610+3314328','21012062+3314280'])
    #dictionary_lspm_object.append('lspm1998')
    #dictionary_2mass_id_mdwarfs.append(['09184624+2645114','09184142+2645526'])
    dictionary_lspm_object.append('lspm524')
    dictionary_2mass_id_mdwarfs.append(['07444018+0333089'])
     
    
    #Loop over all data
    for mearth_years in range(2008,current_year+1):
        for mearth_months in range(1,13):
            for mearth_days in range(1,32):

                #Get the Current Day to go and Find files for
                if mearth_months < 10:
                    months_string = '0'+str(mearth_months)
                else:
                    months_string = str(mearth_months)
                if mearth_days < 10:
                    days_string = '0'+str(mearth_days)
                else:
                    days_string = str(mearth_days)
                current_date_str = str(mearth_years)+months_string+days_string
                print "On day: "+current_date_str

                for directory_loop in range(len(master_data_directories)):                    
                    if directory_loop != 3: #MEarth-North
                        for tel_loop in range(1,9):
                            data_directory = master_data_directories[directory_loop]+'tel0'+str(tel_loop)+'/'+current_date_str+'/'
                            if os.path.exists(data_directory):
                                command = 'ls '+data_directory+'t*.fit > foo.txt'
                                os.system(command)

                                observed_objects = []
                                observed_objects_number_of_exposures = np.zeros(1000)

                                image_file = open('foo.txt','r')
                                for image_name in image_file:
                                    #Get LSPM name
                                    fits_file = pyfits.open(image_name)
                                    target_name = str(fits_file[0].header['OBJECT'])
                                    target_name.replace(" ", "")
                                    #Go from LSPM Object to the 2MASS ID's of the M-dwarf stars IN it
                                    found = 0
                                    for dictionary_search in range(len(dictionary_lspm_object)):
                                        if dictionary_lspm_object[dictionary_search] == target_name:
                                            found = 1
                                            mdwarfs_in_images = dictionary_2mass_id_mdwarfs[dictionary_search]
                                            found_today = 0
                                            for triplea in range(len(mdwarfs_in_images)):
                                                for accounting_loop in range(len(observed_objects)):
                                                    if observed_objects[accounting_loop] == mdwarfs_in_images[triplea]:
                                                        observed_objects_number_of_exposures[accounting_loop] = observed_objects_number_of_exposures[accounting_loop]+1
                                                        found_today = 1
                                            if found_today == 0:
                                                for triplea in range(len(mdwarfs_in_images)):
                                                    observed_objects.append(mdwarfs_in_images[triplea])
                                                    observed_objects_number_of_exposures[len(observed_objects)-1] = observed_objects_number_of_exposures[len(observed_objects)-1]+1
                                    if found == 0:
                                        #add to the dictionary
                                        the_2mass_ids = []
                                        #lc_file = pyfits.open(master_data_directories[directory_loop]+'tel0'+str(tel_loop)+'/master/'+target_name+'_lc.fits')
                                        if target_name[0:2] == 'ls':

                                            lc_file = pyfits.open('/data/mearth1/reduced/'+'tel0'+str(tel_loop)+'/master/'+target_name+'_lc.fits')
                                            print master_data_directories[directory_loop]+'tel0'+str(tel_loop)+'/master/'+target_name+'_lc.fits'
                                            classes = lc_file[1].data['Class']

                                            names = lc_file[1].data['2massid']
                                            for scan in range(len(classes)):
                                                if classes[scan] == 9:
                                                    the_2mass_ids.append(names[scan])
                                                    observed_objects.append(names[scan])
                                                    observed_objects_number_of_exposures[len(observed_objects)-1] = observed_objects_number_of_exposures[len(observed_objects)-1] + 1
                                            dictionary_lspm_object.append(target_name)
                                            dictionary_2mass_id_mdwarfs.append(the_2mass_ids)
                                            pickle.dump( (dictionary_lspm_object,dictionary_2mass_id_mdwarfs), open( "the_dictionary.pickle", "wb" ) )
    
                                        
                                for final_tally in range(len(observed_objects)):
                                    if os.path.exists('/data/mearth2/marples/mo'+str(str(observed_objects[final_tally]).replace(' ',''))) == False:
                                        os.makedirs('/data/mearth2/marples/mo'+observed_objects[final_tally])
                                        temp_file = open('Directories_made.txt','a')
                                        temp_file.write('/data/mearth2/marples/mo'+observed_objects[final_tally]+'\n')
                                        temp_file.close()
                                    file_to_write = open('/data/mearth2/marples/mo'+observed_objects[final_tally]+'/Observation_List.txt','a')
                                    #file_to_write = open('./testing.txt','a')
                                    file_to_write.write(current_date_str+' 0'+str(tel_loop)+' '+str(int(observed_objects_number_of_exposures[final_tally]))+'\n')
                                    file_to_write.close()
                                                        
                                            
                                    
                                                    
                                        
                                
                            

                    if directory_loop == 3: #MEarth-South
                        for tel_loop in range(11,19):
                            data_directory = master_data_directories[directory_loop]+'tel'+str(tel_loop)+'/master/'
                            
                            if os.path.exists(data_directory+'*/*.'+current_date_str):
                                command = 'ls '+data_directory+'*/*.'+current_date_str+'/*/*fits > foo.txt'
                                os.system(command)

                                observed_objects = []
                                observed_objects_number_of_exposures = np.zeros(1000)

                                image_file = open('foo.txt','r')
                                for image_name in image_file:
                                    name,extension = image_name.split('/')
                                    garbage,target_name = name.split('2massj')


                                    m_dwarfs_in_image = []
                                    south_file = pyfits.open(data_directory+name+'_daily.fits')
                                    classes = south_file[1].data['Class']
                                    ids = south_file[1].data['2massid']
                                    for scan in range(len(classes)):
                                        if classes[scan] == 9:
                                            m_dwarfs_in_image.append(ids[scan])


                                    found = 0
                                    for triplea in range(len(m_dwarfs_in_image)):
                                        for accounting_loop in range(len(observed_objects)):
                                            if observed_objects[accounting_loop] == mdwarfs_in_images[triplea]:
                                                observed_objects_number_of_exposures[accounting_loop] = observed_objects_number_of_exposures[accounting_loop]+1
                                                found = 1
                                    if found == 0:
                                        for triplea in range(len(mdwarfs_in_images)):
                                            observed_objects.append(mdwarfs_in_images[triplea])
                                            observed_objects_number_of_exposures[len(observed_objects)-1] = observed_objects_number_of_exposures[len(observed_objects)-1]+1


                                for final_tally in range(len(observed_objects)):
                                    if os.path.exists('/data/mearth2/marples/mo'+observed_objects[final_tally]) == False:
                                        os.makedirs('/data/mearth2/marples/mo'+observed_objects[final_tally])
                                        temp_file = open('Directories_made.txt','a')
                                        temp_file.write('/data/mearth2/marples/mo'+observed_objects[final_tally]+'\n')
                                        temp_file.close()
                                    file_to_write = open('/data/mearth2/marples/mo'+observed_objects[final_tally]+'/Observation_List.txt','a')
                                    file_to_write.write(current_date_str+' '+str(tel_loop)+' '+str(int(observed_objects_number_of_exposures[final_tally]))+'\n')
                                    file_to_write.close()

    finish = open('./Date_Last_Ran.txt','w')
    finish.write(datetime.date.today())
    finish.close()





if __name__ == '__main__':
    main()
