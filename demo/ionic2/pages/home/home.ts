import { Component } from '@angular/core';

import { NavController, AlertController, ActionSheetController, Platform } from 'ionic-angular';
import { AngularFire, FirebaseListObservable } from 'angularfire2';
import {GooglePlus} from 'ionic-native';
import firebase from 'firebase'


@Component({
  selector: 'page-home',
  templateUrl: 'home.html'
})
export class HomePage {
    songs: FirebaseListObservable<any>;
    user: any = {};
    winobj: any = null; // maybe better understand injectables... see chrome tabs

    constructor(public navCtrl: NavController, public alertCtrl: AlertController,
                public af: AngularFire, public actionSheetCtrl: ActionSheetController, private platform: Platform) {
        this.winobj=window;
       
       // suscription equivalent to onAuthStateChanged
       this.af.auth.subscribe(user => {
                if(user) {
                    alert('fire user logged in');
                    this.user = user;
                    this.songs = af.database.list('/songs');
                }else {
                    alert('fire user logged out');
                    this.user = {};
                }
        });

    }

    is_local(){
        if( /^file:\/{3}[^\/]/i.test(this.winobj.location.href) ){
            return true;
        }
        return false;
    }

  login()
  {
    if(this.is_local()){
        GooglePlus.login({
          'webClientId': 'USE-YOURS-HERE!!!!!.apps.googleusercontent.com',
          'offline': true
        }).then((obj) => {
            if (!firebase.auth().currentUser) {
                firebase.auth().signInWithCredential(firebase.auth.GoogleAuthProvider.credential(obj.idToken))
                .then((success) => {
                    this.displayAlert(JSON.stringify(success),"signInWithCredential successful");
                })
                .catch((gplusErr) => {
                    this.displayAlert(JSON.stringify(gplusErr),"GooglePlus failed")
                });
            }
        }).catch( (msg) => {
          this.displayAlert(msg,"Gplus signin failed2")
        });
    }else{
        console.log("no device");
        this.af.auth.login();
    } 
  }
 

 
 
  displayAlert(value,title)
  {
      let coolAlert = this.alertCtrl.create({
      title: title,
      message: JSON.stringify(value),
      buttons: [
                    {
                        text: "Ok"
                    }
               ]
      });
      coolAlert.present();
    }

    logout() {
        if(!this.is_local()){
            this.af.auth.logout();
        }else{
            GooglePlus.logout().then(
                (msg) => {
                      alert('logout ok');
                      if(firebase.auth().currentUser){
                        firebase.auth().signOut();
                      }
                }).catch(
                (msg) => {
                    alert('logout error: '+msg);
                })
            ;
        }
    }


    addSong(){
      let prompt = this.alertCtrl.create({
        title: 'Song Name',
        message: "Enter a name for this new song you're so keen on adding",
        inputs: [
          {
            name: 'title',
            placeholder: 'Title'
          },
        ],
        buttons: [
          {
            text: 'Cancel',
            handler: data => {
              console.log('Cancel clicked');
            }
          },
          {
            text: 'Save',
            handler: data => {
              this.songs.push({
                title: data.title
              });
            }
          }
        ]
      });
      prompt.present();
    }
    showOptions(songId, songTitle) {
      let actionSheet = this.actionSheetCtrl.create({
        title: 'What do you want to do?',
        buttons: [
          {
            text: 'Delete Song',
            role: 'destructive',
            handler: () => {
              this.removeSong(songId);
            }
          },{
            text: 'Update title',
            handler: () => {
              this.updateSong(songId, songTitle);
            }
          },{
            text: 'Cancel',
            role: 'cancel',
            handler: () => {
              console.log('Cancel clicked');
            }
          }
        ]
      });
      actionSheet.present();
    }
    removeSong(songId: string){
      this.songs.remove(songId);
    }
    updateSong(songId, songTitle){
      let prompt = this.alertCtrl.create({
        title: 'Song Name',
        message: "Update the name for this song",
        inputs: [
          {
            name: 'title',
            placeholder: 'Title',
            value: songTitle
          },
        ],
        buttons: [
          {
            text: 'Cancel',
            handler: data => {
              console.log('Cancel clicked');
            }
          },
          {
            text: 'Save',
            handler: data => {
              this.songs.update(songId, {
                title: data.title
              });
            }
          }
        ]
      });
      prompt.present();
    }
}
