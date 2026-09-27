import numpy as np
import pandas as pd

def null_data(data):
    total_null = data.isnull().sum()
    percent_null = (data.isnull().sum()/data.isnull().count()*100)
    percent_null = round(percent_null,1)
    tt = pd.concat([total_null, percent_null], axis=1, keys=['Total Null', 'Percent Null'])
    types = []
    for col in data.columns:
        dtype = str(data[col].dtype)
        types.append(dtype)
    tt['Types'] = types
    return(np.transpose(tt))

def most_frequent_values(data):
    total = data.count()
    tt = pd.DataFrame(total)
    tt.columns = ['Total Non-Null']
    items = []
    vals = []
    for col in data.columns:
        try:
            itm = data[col].value_counts().index[0]
            val = data[col].value_counts().values[0]
            items.append(itm)
            vals.append(val)
        except Exception as ex:
            print(ex)
            items.append(0)
            vals.append(0)
            continue
    tt['Most frequent item'] = items
    tt['Frequency'] = vals
    tt['Percent from total non-null'] = np.round(vals / total * 100, 3)
    return tt.T

def number_unique_values(data):
    total_non_null = data.count()
    nunique = data.nunique()
    # print(f"uniques: {uniques}")
    tt = pd.concat([total_non_null,nunique],axis=1,keys=["Total Non-Null","Number of uniques"])

    return tt.T