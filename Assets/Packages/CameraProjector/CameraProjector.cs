using UnityEngine;


/// <summary>
/// Projector from Camera
/// </summary>
[ExecuteInEditMode]
[RequireComponent(typeof(Projector))]
public class CameraProjector : MonoBehaviour
{
    public Camera _camera;
    public Vector2Int texSize = new Vector2Int(1920, 1080);
    public float _fovOffset = 30f; // to fix wrong culling when custom projectionmatrix

    Projector _projector;
    public Material material { get { return (_projector != null ) ? _projector.material : null; } }

    void Start()
    {
        _projector = GetComponent<Projector>();
        _projector.material = new Material(_projector.material); // material instantiate
        _projector.ignoreLayers = ~(1 << gameObject.layer);

        _camera = _camera ?? GetComponent<Camera>();
        _camera.cullingMask &= _camera.cullingMask & ~(1 << gameObject.layer);
        
        if ( _camera.targetTexture == null )
        {
            var tex = new RenderTexture(texSize.x, texSize.y, 0);
            _camera.targetTexture = tex;
        }
    }

    public void Update()
    {
        // WARN: maybe wrong culling if camera has custom projectionmatrix
        _projector.nearClipPlane = _camera.nearClipPlane;
        _projector.farClipPlane = _camera.farClipPlane;
        _projector.fieldOfView = Mathf.Min(180f, _camera.fieldOfView + _fovOffset);
        _projector.aspectRatio = _camera.aspect;
        _projector.orthographic = _camera.orthographic;
        _projector.orthographicSize = _camera.orthographicSize;
    }

    public void LateUpdate()
    {
        material.SetTexture("_ProjectorTex", _camera.targetTexture);

        var localToCameraMatrix = Matrix4x4.Scale(new Vector3(1f, 1f, -1f));
        var worldToCameraMatrix = localToCameraMatrix * transform.worldToLocalMatrix; 
       // worldToCameraMatrix = _camera.worldToCameraMatrix;

        material.SetMatrix("_ProjectorVPMatrix", _camera.projectionMatrix * worldToCameraMatrix);
    }
}
