import { Injectable } from '@angular/core';
import { HttpInterceptor, HttpRequest, HttpHandler, HttpErrorResponse, HttpEvent, HttpResponse, HttpHeaders } from '@angular/common/http';
import { Observable , of, throwError,} from 'rxjs';
import { catchError,tap, map, finalize, switchMap, retryWhen, delay, concatMap} from 'rxjs/operators';
import { environment } from '../environments/environment';
import { Router } from '@angular/router';


@Injectable()
export class authInterceptor implements HttpInterceptor {

  constructor( private router : Router){ };

  public ranRefreshOnce : boolean = false; 
  intercept(
    req: HttpRequest<any>,
    next: HttpHandler
  ): Observable<HttpEvent<any>> {    
    //fetching token from Session Storage
    const id_token: any = sessionStorage.getItem('id_token');
    const access_token: any = sessionStorage.getItem('access_token');
    const refresh_tokens : any = sessionStorage.getItem('refresh_token');
    const modReequest = req.clone({
      //setting the headers for all the request to the backend
      setHeaders: {
        'access-token': access_token,
        'id-token': id_token,
      },
    });
    return next.handle(modReequest).pipe(map((event:HttpEvent<any>)=>
    {
      //if in future you want to add some url or padd anything specifically to some url etc you can add here 
      return event;
    }),
    catchError((error): Observable<HttpEvent<any>>=>
    {
      if(403 === error.status){
        this.router.navigate(['/accessdenied'])
      }else if(401 === error.status){      
        return this.refreshSecCall(modReequest,  refresh_tokens, next).pipe(
          switchMap((secondApiRes)=>
          {
          //this is second call for token expiry url and we are updating the headers here 
          let acess_tok_head = sessionStorage.getItem('access_token');
          let idTok_tok_head2 = sessionStorage.getItem('id_token');
          const modReequests =  new HttpHeaders({
            'access-token' : acess_tok_head ?? '',
            'id-token': idTok_tok_head2 ?? ''            
          })          
          const upReq = modReequest.clone({
            headers : modReequests,
          });          
          //once token has been setup this call will be hit to carry the last failed operation
            return this.retryOriginalRequest(upReq, next);             
          })
        );  
      }
      else {
        //If we are getting stringified response 
        let errorToshow;
        try {
          errorToshow = JSON.parse(error.error);
        } catch (err) {
          errorToshow = error?.error;
        }        
        console.log('hello errorsss =>', error)
      }
      return throwError(() => new Error(error));
    })
    );
  }

  private refreshSecCall(request: HttpRequest<any>, refresh_token: string,next:HttpHandler) {        
    const redirect_uri : any = environment.redirectUri;
    //here we are updating the headers to make refresh token call
    let headers = request.headers.keys().reduce((acc, key)=>
    {
      if(key !== "id-token" && key != "access-token")
      {
        acc = acc.set(key, request.headers.get(key)!);
      }
      return acc;
    }, new HttpHeaders());
    headers =  headers.set('refresh-token', refresh_token);
    headers =  headers.set('redirect-uri', redirect_uri);
    const refreshcall = request.clone({      
      url : environment.refreshTokenApi,
      method: 'GET',
      headers
    })
    return next.handle(refreshcall).pipe(tap((res)=>
    {
      if( res instanceof HttpResponse)
      {
        //parsing it bcs in one api i am getting stringified response while in others I am getting normal response
        let sessionDetailsTBF: any;
        try {
          sessionDetailsTBF = JSON.parse(res.body);
        } catch (error) {
          sessionDetailsTBF = res.body;
        }        
        // resetting the session storage 
        sessionStorage.setItem('access_token', sessionDetailsTBF?.access_token);
        sessionStorage.setItem('id_token', sessionDetailsTBF?.id_token);
        sessionStorage.setItem('refresh_token', sessionDetailsTBF?.refresh_token);       
      }
    },
    (error)=>
    {
      console.log('error status', error.status)
      if(error.status == 300)
      {
        // where to redirect this
        window.location.reload()
        console.log('300 status ', error)
      }
     
      console.log('error came during the feteching of code from api side', error);   
    }
    ),
    finalize(()=>
    {
      this.ranRefreshOnce = false;
    })
    )
  }

  private retryOriginalRequest(request : HttpRequest<any>, next:HttpHandler): Observable<HttpEvent<any>>{
    return next.handle(request).pipe(
      retryWhen((errors)=>
      {
        return errors.pipe(          
          concatMap((error, retryCount) => {
            if(error.status !== 403)
            {            
              }else if(retryCount < 3){
                  return of(request).pipe(delay(5000));
            }           
            return throwError(() => new Error(error));
          })
        );       
      })

    )
  }
   
}

