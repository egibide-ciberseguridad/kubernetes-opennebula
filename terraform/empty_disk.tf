resource "opennebula_image" "empty_disk" {
  name         = "kubernetes-empty-disk"
  description  = "Imagen para los discos de datos de los nodos de Kubernetes"
  datastore_id = 1
  type         = "DATABLOCK"
  size         = "1024"
}
