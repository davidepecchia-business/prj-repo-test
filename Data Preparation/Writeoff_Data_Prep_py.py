#!/usr/bin/env python
# coding: utf-8

# ## Python Sample Data Prep

# In[1]:


import pandas as pd
import numpy as np
import swat
import getpass


# In[2]:


viyahost='10.96.5.25'

# Specify your SAS Viya username and password
username='sasdemo'
print('Provide Password:')
password=getpass.getpass()
s = swat.CAS(viyahost, 5570, username=username, password=password)


# In[3]:


df=pd.read_csv("CREDITWRITEOFF.csv")


# In[4]:


df.head()


# In[5]:


df.describe()


# In[6]:


df.info()


# In[7]:


df_rmw = df.drop(["ROC1", "ROC12", "ROC3"], axis=1)


# In[8]:


df_rmw.info()
df_rmw.to_csv('creditwriteoff_prepped_py.csv')


# In[9]:


result = s.upload_frame(df_rmw, casout={"caslib":'input',"name":'creditwriteoff_prep_py', "promote":True})


# In[ ]:




