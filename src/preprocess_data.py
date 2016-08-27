 # -*- coding: ISO-8859-1 -*-
'''
Created on 5.7.2016

@author: Jesse
'''
import pandas as pd
import numpy as np
import re
from os import listdir,makedirs
from os.path import exists

pd.set_option('display.expand_frame_repr', None)

# Parameters
input_folders = ['./data/raw_manual/', './data/raw/']
output_folder = './data/preprocessed/'

def process_data(input_folders,output_folder):
    
    # Fetch tracklists
    files = []
    for folder in input_folders:
        files += [folder + file for file in listdir(folder)]
    df_list = []
    
    # Process each tracklist
    for file in files:
        
        episode = file.split('/')[-1][:3]
        
        with open(file,'r',encoding='ISO-8859-1') as f:
            text = f.read()
            
        text = text \
                    .replace('â\x80\x93',"-") \
                    .replace('â\x80\x99',"'") \
                    .replace('\x85','...') \
                    .replace('\x92',"'") \
                    .replace('\x96',"-") \
                    .replace('<strong>',' ') \
                    .replace('</strong>',' ') \
                    .replace('ï»¿','')
        lines = text.split('\n')
        
        # Date
        date = ",".join(lines[0].split(",")[0:2])
        
        lines = lines[1:]
            
        for enum,line in enumerate(lines):
            
            line0 = line
            line = line.strip()
            
            # Tune of the week
            totw = False
            totw_matches = re.findall('TUNE OF THE WEEK', line, flags=re.IGNORECASE)
            if len(totw_matches) >= 1:
                totw = True
                line = re.sub("(TUNE OF THE WEEK.*?)\s", '', line, flags=re.IGNORECASE)
                
            # Future favorite
            ff = False
            ff_matches = re.findall('FUTURE FAVORITE|FUTURE FAVOURITE', line, flags=re.IGNORECASE)
            if len(ff_matches) >= 1:
                ff = True
                line = re.sub("(FUTURE FAVORITE.*?)\s", '', line, flags=re.IGNORECASE)
                line = re.sub("(FUTURE FAVOURITE.*?)\s", '', line, flags=re.IGNORECASE)
                
            # ASOT Radio classic
            rc = False
            rc_matches = re.findall('ASOT RADIO CLASSIC|RADIO CLASSIC|ASOT CLASSIC', line, flags=re.IGNORECASE)
            if len(rc_matches) >= 1:
                rc = True
                line = re.sub("(ASOT RADIO CLASSIC.*?)\s", '', line, flags=re.IGNORECASE)
                line = re.sub("(RADIO CLASSIC.*?)\s", '', line, flags=re.IGNORECASE)
                line = re.sub("(ASOT CLASSIC.*?)\s", '', line, flags=re.IGNORECASE)
                
            # Trending track
            tt = False
            tt_matches = re.findall('TRENDING TRACK', line, flags=re.IGNORECASE)
            if len(tt_matches) >= 1:
                tt = True
                line = re.sub("(TRENDING TRACK.*?)\s", '', line, flags=re.IGNORECASE)
                
            # Progressive pick
            pp = False
            pp_matches = re.findall('PROGRESSIVE PICK', line, flags=re.IGNORECASE)
            if len(pp_matches) >= 1:
                pp = True
                line = re.sub("(PROGRESSIVE PICK.*?)\s", '', line, flags=re.IGNORECASE)
            
            # Extract () and []
            brackets = re.findall("([\(|\[].*?[\)|\]])", line)
            
            remix = False
            remixer = np.NaN
            bootleg = False
            mashup = False
            label = np.NaN
            for b in brackets:
                
                line = line.replace(b,'')
                is_label = True
                
                # Remix
                if any(word in b.lower() for word in ['remix','mix']) and not any(word in b.lower() for word in ['original']):
                    remix = True
                    remixer = b
                    for p in ["REMIXED", "REMIX", "MIXED", 'MIX','CLUB','EXTENDED',]:
                        remixer = re.sub(p,'', remixer, flags=re.IGNORECASE)
                    remixer = re.sub('[\(|\[]|[\)|\]]','',remixer).strip()
                    if not remixer.isupper():
                        remixer = remixer.title()
                    is_label = False
                
                # Bootleg
                if any(word.lower() in b.lower() for word in ['bootleg']):
                    bootleg = True
                    is_label = False
                
                # Mashup
                if any(word.lower() in b.lower() for word in ['mash']):
                    mashup = True
                    is_label = False
                
                # Label
                if is_label:
                    label = b[1:-1]
                    if not label.isupper():
                        label = label.title()
            
            # Number
            nb = re.findall("^[0-9]{1,3}",line)
            if len(nb) == 1:
                nb = nb[0]
            else:
                nb = np.NaN
            
            # Artist
            artist = re.findall("^[0-9]{1,3}\.(.*?)\s*-",line)
            if len(artist) == 1:
                artist = artist[0].strip()
                if not artist.isupper():
                    artist = artist.title()
                if artist in ['', 'Unknown Artist', '???','ID','?']:
                    artist = np.NaN
            else:
                artist = np.NaN
                
            # Title
            title = line.split('-')
            if len(title) >= 2:
                title = "-".join(title[1:]).strip()
                if not title.isupper():
                    title = title.title()
                if title in ['','?','Unknown','Unknown Title','ID']:
                    title = np.NaN
                    
            else:
                title = np.NaN
                
            df_list.append([episode,date,enum+1,nb,label,artist,title,remix,remixer,bootleg,mashup,totw,ff,rc,tt,pp,line0])
    
    # Convert to dataframe
    df = pd.DataFrame(df_list, columns=['episode','date','enum','nb','label','artist','title','remix','remixer','bootleg','mashup','totw','ff','rc','tt','pp','line'])
    
    # Fine-tuning
    # Featuring / presents / versus
    df['artist'] = df.artist.str.replace('featuring','feat.', case=False)\
                            .str.replace('ft.', 'feat.', case=False)\
                            .str.replace(' ft ', ' feat. ', case=False)\
                            .str.replace(' feat ',' feat. ', case=False)\
                            .str.replace('presents','pres.', case=False)\
                            .str.replace(' vs ',' vs. ', case=False)\
                            .str.replace('versus','vs.', case=False)
                            
    # Date to datetime
    df['date'] = pd.to_datetime(df.date, format="%B %d, %Y")
    
    # Save results
    output_path = output_folder + 'df.csv'
    df.to_csv(output_path, encoding='utf-8', index=False, sep=";")
    print('Preprocessing done in %s!' % output_path)
    
    # Print episode gaps
    missing_episodes = []
    episodes_processed = df.episode.unique().astype(np.int32)
    for ep in range(1,np.max(episodes_processed)):
        if ep not in episodes_processed:
            missing_episodes.append(ep)
    print('\nMissing episodes:',missing_episodes)


def main():
    
    if not exists(output_folder):
        makedirs(output_folder)
    
    process_data(input_folders,output_folder)
    
if __name__ == '__main__':
    main()