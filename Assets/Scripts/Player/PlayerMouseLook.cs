using UnityEngine;

namespace SmallTail.Player
{
    public class PlayerMouseLook : MonoBehaviour
    {
        [SerializeField] private float _sensitivity;

        private Transform _character;
        private Vector2 _mouseLook;

        private void Awake()
        {
            _character = transform.parent;
            
            Cursor.visible = false;
            Cursor.lockState = CursorLockMode.Locked;
        }

        private void Update()
        {
            float mouseX = Input.GetAxisRaw("Mouse X");
            float mouseY = Input.GetAxisRaw("Mouse Y");
            
            Vector2 movement = new Vector2(mouseX, mouseY);
            movement *= _sensitivity * Time.deltaTime;    

            _mouseLook += movement;
            _mouseLook.y = ClampAngle(_mouseLook.y, -90f, 90f);
            
            transform.localRotation = Quaternion.AngleAxis(-_mouseLook.y, Vector3.right);
            _character.localRotation = Quaternion.AngleAxis(_mouseLook.x, _character.transform.up);
        }
        
        private float ClampAngle(float angle, float min, float max)
        {
            if (angle < -360F)
            {
                angle += 360F;
            }

            if (angle > 360F)
            {
                angle -= 360F;
            }

            return Mathf.Clamp(angle, min, max);
        }
    }
}