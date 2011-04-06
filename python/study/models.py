# -*- coding: utf-8 -*-
# study.models

from google.appengine.ext import db

# Create your models here.

class ImgModel(db.Model):
    img = db.BlobProperty()
    title = db.StringProperty()
    date = db.DateTimeProperty()
    
import random

NUM_SHARDS = 20
    
class GenericCounter(db.Model):
    name = db.StringProperty()
    count = db.IntegerProperty(required=True, default = 0)    
    
    def get_count(self, cnt_name):
        total = 0
        counters = GenericCounter.gql('WHERE name =:1', cnt_name)
        if counters.count() >= 1:
            for counter in counters:
                total += counter.count
        return total
    
    def countup(self, cnt_name, inc):
        def txn():
            index = random.randint(0, NUM_SHARDS - 1)
            shard_name = 'shard' + str(index)
            counter = GenericCounter.get_by_key_name(shard_name)
            if counter is None:
                counter = GenericCounter(key_name=shard_name) 
                counter.name = cnt_name
            counter.count += inc
            counter.put()           
        db.run_in_transaction(txn)
    
    def increment(self, cnt_name):
        self.countup(cnt_name, 1)
        
            