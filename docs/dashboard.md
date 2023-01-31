# Instalar el Dashboard UI en el cluster Kubernetes

1. Acceder al controlador:

    ```
    make ssh
    ```

2. Instalar el Dashboard:

    ```
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
    ```

3. Publicar el Dashboard en localhost (del master, no tenemos acceso remoto todavía):

    ```
    kubectl proxy &
    ```

4. Crear el usuario admin y obtener el token de acceso:

    ```
    kubectl apply -f https://gist.githubusercontent.com/ijaureguialzo/e75af60c795ca7f5a226ba76dd94689c/raw/79d29f5ca39ab66eff63e6becf607a8e13c1a475/service-account.yml
    kubectl apply -f https://gist.githubusercontent.com/ijaureguialzo/e75af60c795ca7f5a226ba76dd94689c/raw/79d29f5ca39ab66eff63e6becf607a8e13c1a475/role-binding.yml
    ```

    ```
    kubectl -n kubernetes-dashboard create token admin-user
    ```

   Ejemplo de token:

    ```
    eyJhbGciOiJSUzI1NiIsImtpZCI6IlJsaTBuc0ktZm5QQ2NPSDdsSXgxZDBFclUzbHVMaTM0Z05JcE90QW9nLWsifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiXSwiZXhwIjoxNjc1MTYwNjkwLCJpYXQiOjE2NzUxNTcwOTAsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJrdWJlcm5ldGVzLWRhc2hib2FyZCIsInNlcnZpY2VhY2NvdW50Ijp7Im5hbWUiOiJhZG1pbi11c2VyIiwidWlkIjoiNTU4ZGIwMWMtM2E4My00NTU4LWEwMzUtYTliNzIyODkzMDk4In19LCJuYmYiOjE2NzUxNTcwOTAsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDprdWJlcm5ldGVzLWRhc2hib2FyZDphZG1pbi11c2VyIn0.EktZUbngZrs6HrG9nP5MQlhUp_ubRbV8QlhGaaN5JRFIBwDtNnYLfzZh7ubkcFFIrHFs4V3_rSzUCanrl4y8gRvyyNlCH6ii0wj1vy21OXYyVR87zqlix7tY5o74agG4wo5Pi4t3ovWbVriIGEnKRVBUeX9IMyc-cNFPKkthkV2sRKf8pffmMJ4EpWtIZSHGqGH8tRh4oSvNENAdelp-SqXhb3tQ2yv5owemHNGVSqciu9UuWXWKJ8f8kjBDzQTaZywgyxaMeXMoVOYh0f7Z4a-kVyOmPIg4NLtc6snjylnYfsPS_pYcR8emsntQ0AYgG19llhRBWo33GdKYXnxaxw
    ```

5. Salir de la sesión remota en el controlador:

    ```
    exit
    ```

6. Redireccionar el puerto local del controlador a nuestra máquina local:

    ```
    ssh -L 9999:127.0.0.1:8001 -N -f -l root $(docker compose run --rm terraform-ansible terraform -chdir=/terraform output -raw master_connection_ip)
    ```

7. Acceder
   al [Dashboard](http://localhost:9999/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/workloads?namespace=default).

## Referencias

- https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/
- https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md
- https://stackoverflow.com/questions/59020970/kubernetes-remote-access-dashboard
