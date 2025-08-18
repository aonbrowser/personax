import React, { useEffect, useState } from 'react';
import { Text, View, Button, ScrollView, TouchableOpacity, Alert, TextInput } from 'react-native';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';

const SERVER = 'http://localhost:8080';
const Stack = createNativeStackNavigator();

function LikertRow({ item, onChange, value }: any) {
  const opts = (item.options_tr||'').split('|');
  return (
    <View style={{ marginBottom:16 }}>
      <Text style={{ marginBottom:6 }}>{item.text_tr}</Text>
      <View style={{ flexDirection:'row', flexWrap:'wrap', gap:6 }}>
        {opts.map((opt:string, idx:number)=> (
          <TouchableOpacity key={idx} onPress={()=> onChange(idx+1)} style={{ padding:8, borderWidth:1, borderColor: (value===idx+1?'#333':'#e5e5e5'), borderRadius:6 }}>
            <Text>{opt}</Text>
          </TouchableOpacity>
        ))}
      </View>
    </View>
  );
}

function TextRow({ item, onChange, value }: any) {
  return (
    <View style={{ marginBottom: 16 }}>
      <Text style={{ marginBottom: 6 }}>{item.text_tr}</Text>
      <TextInput
        multiline
        value={value||''}
        onChangeText={(t)=> onChange(t)}
        placeholder="Yazınız…"
        style={{ borderWidth:1, borderColor:'#e5e5e5', borderRadius:8, padding:10, minHeight:80 }}
      />
      {item.notes ? <Text style={{ fontSize:12, opacity:0.6, marginTop:4 }}>{item.notes}</Text> : null}
    </View>
  );
}

function NumberRow({ item, onChange, value }: any) {
  return (
    <View style={{ marginBottom: 16 }}>
      <Text style={{ marginBottom: 6 }}>{item.text_tr}</Text>
      <TextInput
        keyboardType="numeric"
        value={value?String(value):''}
        onChangeText={(t)=> onChange(t.replace(/[^0-9]/g,''))}
        placeholder="Örn: 28"
        style={{ borderWidth:1, borderColor:'#e5e5e5', borderRadius:8, padding:10 }}
      />
    </View>
  );
}

function SingleChoiceRow({ item, onChange, value }: any) {
  const opts = (item.options_tr||'').split('|');
  return (
    <View style={{ marginBottom: 16 }}>
      <Text style={{ marginBottom: 6 }}>{item.text_tr}</Text>
      <View style={{ flexDirection:'row', flexWrap:'wrap', gap:6 }}>
        {opts.map((opt:string, idx:number)=> (
          <TouchableOpacity key={idx} onPress={()=> onChange(opt)} style={{ padding:8, borderWidth:1, borderColor:(value===opt?'#333':'#e5e5e5'), borderRadius:6 }}>
            <Text>{opt}</Text>
          </TouchableOpacity>
        ))}
      </View>
      {item.notes ? <Text style={{ fontSize:12, opacity:0.6, marginTop:4 }}>{item.notes}</Text> : null}
    </View>
  );
}

function MultiSelectRow({ item, onChange, value }: any) {
  const opts = (item.options_tr||'').split('|');
  const selected = new Set((value||[]));
  function toggle(opt:string){
    if (selected.has(opt)) selected.delete(opt); else selected.add(opt);
    onChange(Array.from(selected));
  }
  return (
    <View style={{ marginBottom: 16 }}>
      <Text style={{ marginBottom: 6 }}>{item.text_tr}</Text>
      <View style={{ flexDirection:'row', flexWrap:'wrap', gap:6 }}>
        {opts.map((opt:string, idx:number)=> (
          <TouchableOpacity key={idx} onPress={()=> toggle(opt)} style={{ padding:8, borderWidth:1, borderColor: (selected.has(opt)?'#333':'#e5e5e5'), borderRadius:6 }}>
            <Text>{opt}</Text>
          </TouchableOpacity>
        ))}
      </View>
      {item.notes ? <Text style={{ fontSize:12, opacity:0.6, marginTop:4 }}>{item.notes}</Text> : null}
    </View>
  );
}

function RankedMultiRow({ item, onChange, value }: any) {
  const opts = (item.options_tr||'').split('|');
  const order: string[] = Array.isArray(value)? value : [];
  function toggle(opt:string){
    const idx = order.indexOf(opt);
    if (idx>=0){ order.splice(idx,1); } else { order.push(opt); }
    onChange([...order]);
  }
  return (
    <View style={{ marginBottom: 16 }}>
      <Text style={{ marginBottom: 6 }}>{item.text_tr}</Text>
      <View style={{ flexDirection:'row', flexWrap:'wrap', gap:6 }}>
        {opts.map((opt:string, idx:number)=> {
          const pos = order.indexOf(opt);
          return (
            <TouchableOpacity key={idx} onPress={()=> toggle(opt)} style={{ padding:8, borderWidth:1, borderColor: (pos>=0?'#333':'#e5e5e5'), borderRadius:6 }}>
              <Text>{pos>=0 ? `${pos+1}. ${opt}` : opt}</Text>
            </TouchableOpacity>
          );
        })}
      </View>
      {item.notes ? <Text style={{ fontSize:12, opacity:0.6, marginTop:4 }}>{item.notes}</Text> : null}
    </View>
  );
}

function MultiRow({ item, onChange, value }: any) {
  const opts = (item.options_tr||'').split('|');
  return (
    <View style={{ marginBottom:16 }}>
      <Text style={{ marginBottom:6 }}>{item.text_tr}</Text>
      <View style={{ gap:6 }}>
        {opts.map((opt:string, idx:number)=> (
          <TouchableOpacity key={idx} onPress={()=> onChange(opt)} style={{ padding:8, borderWidth:1, borderColor: (value===opt?'#333':'#e5e5e5'), borderRadius:6 }}>
            <Text>{opt}</Text>
          </TouchableOpacity>
        ))}
      </View>
    </View>
  );
}

function S0ProfileScreen({ navigation }: any) {
  const [items, setItems] = useState<any[]>([]);
  const [answers, setAnswers] = useState<any>({});
  useEffect(()=>{ fetch(SERVER + '/v1/items/by-form?form=S0_profile').then(r=>r.json()).then(d=> setItems(d.items||[])); },[]);
  function setAnswer(id:string, val:any){ setAnswers((p:any)=> ({...p,[id]:val})); }
  function submit(){
    Alert.alert('Profil Kaydedildi', 'Artık S1 testine geçebilirsiniz.', [
      { text:'S1’e Geç', onPress:()=> navigation.navigate('S1Form') }
    ]);
  }
  return (
    <ScrollView contentContainerStyle={{ padding:24 }}>
      <Text style={{ fontSize:18, fontWeight:'700' }}>Profil & Yaşam Bağlamı (S0)</Text>
      {items.length===0 ? <Text style={{opacity:0.6}}>Form yükleniyor…</Text> :
        items.map((it:any)=> {
          const v = answers[it.id];
          if (it.type==='OpenText') return <TextRow key={it.id} item={it} value={v} onChange={(x:any)=> setAnswer(it.id,x)} />;
          if (it.type==='SingleChoice') return <SingleChoiceRow key={it.id} item={it} value={v} onChange={(x:any)=> setAnswer(it.id,x)} />;
          if (it.type==='Number') return <NumberRow key={it.id} item={it} value={v} onChange={(x:any)=> setAnswer(it.id,x)} />;
          if (it.type==='MultiSelect') return <MultiSelectRow key={it.id} item={it} value={v} onChange={(x:any)=> setAnswer(it.id,x)} />;
          if (it.type==='RankedMulti') return <RankedMultiRow key={it.id} item={it} value={v} onChange={(x:any)=> setAnswer(it.id,x)} />;
          return <LikertRow key={it.id} item={it} value={v} onChange={(x:any)=> setAnswer(it.id,x)} />;
        })
      }
      {items.length>0 && <Button title="Kaydet ve S1’e Geç" onPress={submit} />}
    </ScrollView>
  );
}

function S1FormScreen({ navigation }: any) {
  const [items, setItems] = useState<any[]>([]);
  const [answers, setAnswers] = useState<any>({});
  useEffect(()=>{ fetch(SERVER + '/v1/items/by-form?form=S1_self').then(r=>r.json()).then(d=> setItems(d.items||[])); },[]);
  function setAnswer(id:string, val:any){ setAnswers((p:any)=> ({...p,[id]:val})); }
  function submit(){ Alert.alert('S1 Kaydedildi', Object.keys(answers).length + ' yanıt'); navigation.goBack(); }
  return (
    <ScrollView contentContainerStyle={{ padding:24 }}>
      <Text style={{ fontSize:18, fontWeight:'700' }}>Kendi Analizim (S1)</Text>
      {items.length===0 ? <Text style={{opacity:0.6}}>Form yükleniyor…</Text> :
        items.map((it:any)=> {
          const v = answers[it.id];
          if (it.type==='OpenText') return <TextRow key={it.id} item={it} value={v} onChange={(x:any)=> setAnswer(it.id,x)} />;
          if (it.type==='MultiChoice5' || it.type==='MultiChoice3') return <MultiRow key={it.id} item={it} value={v} onChange={(x:any)=> setAnswer(it.id,x)} />;
          if (it.type==='ForcedChoice2') return <MultiRow key={it.id} item={{...it, options_tr:'A|B'}} value={v} onChange={(x:any)=> setAnswer(it.id,x)} />;
          return <LikertRow key={it.id} item={it} value={v} onChange={(x:any)=> setAnswer(it.id,x)} />;
        })
      }
      {items.length>0 && <Button title="Gönder" onPress={submit} />}
    </ScrollView>
  );
}

function Home({ navigation }: any){
  return (
    <ScrollView contentContainerStyle={{ padding:24 }}>
      <Text style={{ fontSize:22, fontWeight:'700' }}>Relate Coach</Text>
      <Button title="Kendi Analizim (S0 → S1)" onPress={()=> navigation.navigate('S0Profile')} />
    </ScrollView>
  );
}

export default function App(){
  return (
    <NavigationContainer>
      <Stack.Navigator screenOptions={{ headerShown:false }}>
        <Stack.Screen name="Home" component={Home} />
        <Stack.Screen name="S0Profile" component={S0ProfileScreen} />
        <Stack.Screen name="S1Form" component={S1FormScreen} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
