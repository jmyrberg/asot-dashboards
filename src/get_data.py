 # -*- coding: ISO-8859-1 -*-
'''
Created on 5.7.2016

@author: Jesse
'''
import requests
import re
import time
import pandas as pd
from os.path import exists
from os import makedirs
from html.parser import HTMLParser

# Parameters
output_folder = './data/raw/'
min_episode = 1
max_episode = 800


def invalid_tracks(tracks):
    if len(tracks) < 6:
        return(True)
    if tracks[0] == '':
        return(True)

def get_episode(episode_number,output_folder):
    
    episode_nb = str(episode_number).zfill(3)
    full_url = 'http://www.astateoftrance.com/episodes/episode-' + episode_nb
    full_output_folder = output_folder + episode_nb + '.txt'
       
    if not exists(full_output_folder):
           
        try:
            
            print('\nRequesting %s...' % full_url)
            
            # Request and pattern match
            h = requests.get(full_url)
            text = h.text[10:]
            time.sleep(0.1)
            
            # Try to fetch date
            try:
                date = re.findall("""<abbr class="col w60">(.*?)</abbr>""",text)[-1]
            except Exception as e:
                date = ''
            
            # Default pattern: 
            # 1. Warrior- Voodoo (Oliver Lieb mix) (Incentive promo)
            tracks = re.findall("([0-9]{1,2}\.[^0-9]\s*.*?)<br", text)
            
            # Pattern 2
            if invalid_tracks(tracks):
                tracks = re.findall("<li><strong>(.*?)<\/strong>(.*?)<\/li>", text)
                tracks = [str(i+1) + '. ' + " - ".join(track) for i,track in enumerate(list(tracks))]
                
            if invalid_tracks(tracks):
                tracks = re.findall("([0-9]{1,2}\.\t.*?)[\n|<\/]", text)
            
            if not invalid_tracks(tracks):
            
                # Convert ASCII
                html_parser = HTMLParser()
                tracks = [html_parser.unescape(track) for track in tracks]
                
                # Remove tabs, line breaks and newlines
                tracks = [' '.join(track.split()) for track in tracks]
                
                # Take unique tracks
                tracks = pd.unique(tracks)
                
                # Write output to txt
                with open(full_output_folder, 'w', encoding='utf-8') as f:
                    f.write(date + '\n')
                    f.write('\n'.join(tracks))
                print('File written in %s!' % full_output_folder)
                
            if 'Error 404 - Not Found' in text:
                print('EPISODE %s ERROR 404!' % episode_nb)
                
            if exists(full_output_folder):
                return(True)
            else:
                return(False)
            
        except Exception as e:
            print('EPISODE %s ERROR: %s' % (episode_nb,e))
            return(False)
            
    else:
        return(True)
    
def main():
    
    if not exists(output_folder):
        makedirs(output_folder)
    
    episodes_missing = []

    for ep_num in range(min_episode,max_episode):
        fetched = get_episode(ep_num,output_folder)
        
        if not fetched:
            episodes_missing.append(ep_num)
                
    # These episodes are fetched manually
    print('\n%d episodes missing:' % len(episodes_missing)) 
    for e in episodes_missing:
        print(e)

if __name__ == '__main__':
    main()
    