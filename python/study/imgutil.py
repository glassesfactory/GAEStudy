'''
Created on 2011/04/02

@author: MEGANE
'''

from models import ImgModel
from models import GenericCounter
from google.appengine.ext import db

import datetime

class SimpleImgUtil(object):
    def load(self, title):
        try:
            model = ImgModel.gql('WHERE title =:1', title ).get()
            return model.img
        except:
            return 'Error'
            
    def upload(self, img, title):
        #status = ''
        def txn():
            try:
                model = ImgModel()
                model.img = db.Blob(str(img))
                model.title = title
                model.date = datetime.datetime.now()
                model.put()
                return 'Success'
            except:
                return 'Upload Error'
        status = db.run_in_transaction(txn)
        if status != 'UploadError' :
            count_model = GenericCounter()
            count_model.increment('img')
        return status
    
    def getImgList(self, count = 1000):
        titles = []
        try:
            models = ImgModel.all().order('-date').fetch(count)
            for model in models:
                titles.append(str(model.title))
            return titles
        except:
            return 'Error'
    
    def getModelNum(self):
        model = GenericCounter()
        return model.get_count('img')
